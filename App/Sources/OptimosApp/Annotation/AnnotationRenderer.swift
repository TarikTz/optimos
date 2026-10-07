import AppKit
import CoreGraphics

/// Draws annotations into a context whose coordinates are display-local points with a top-left
/// origin (y down). The on-screen preview and the exported image use this same code, so what the
/// user sees is what gets copied or saved.
enum AnnotationRenderer {
    /// Edge of one pixelated block, in points. Large enough that text underneath cannot be read.
    static let pixelBlock: CGFloat = 12

    /// - Parameters:
    ///   - source: the screenshot to sample for pixelation.
    ///   - sourceOrigin: where the top-left of `source` sits, in the annotations' point space.
    ///   - pointScale: source pixels per point.
    static func draw(
        _ annotations: [Annotation], in ctx: CGContext, source: CGImage, sourceOrigin: CGPoint = .zero,
        pointScale: CGFloat
    ) {
        // Pixelate and blur always sit below the other annotations so a shape drawn over them stays visible.
        for annotation in annotations where annotation.isRedaction {
            switch annotation.kind {
            case .pixelate(let rect):
                hide(rect, in: ctx, source: source, sourceOrigin: sourceOrigin, pointScale: pointScale, smooth: false)
            case .blur(let rect):
                hide(rect, in: ctx, source: source, sourceOrigin: sourceOrigin, pointScale: pointScale, smooth: true)
            default:
                break
            }
        }
        for annotation in annotations where !annotation.isRedaction {
            draw(annotation, in: ctx)
        }
    }

    private static func draw(_ annotation: Annotation, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(annotation.color.cgColor)
        ctx.setFillColor(annotation.color.cgColor)
        ctx.setLineWidth(annotation.size.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        switch annotation.kind {
        case .rectangle(let rect):
            ctx.stroke(rect)
        case .ellipse(let rect):
            ctx.strokeEllipse(in: rect)
        case .line(let from, let to):
            ctx.move(to: from)
            ctx.addLine(to: to)
            ctx.strokePath()
        case .highlight(let rect):
            ctx.setFillColor(annotation.color.cgColor.copy(alpha: 0.4) ?? annotation.color.cgColor)
            ctx.fill(rect)
        case .marker(let center, let number):
            drawMarker(number, at: center, size: annotation.size, color: annotation.color, in: ctx)
        case .arrow(let from, let to):
            for (a, b) in arrowSegments(from: from, to: to, lineWidth: annotation.size.lineWidth) {
                ctx.move(to: a)
                ctx.addLine(to: b)
            }
            ctx.strokePath()
        case .text(let origin, let string):
            drawText(string, at: origin, size: annotation.size, color: annotation.color, in: ctx)
        case .pixelate, .blur:
            break
        }
    }

    private static func drawMarker(
        _ number: Int, at center: CGPoint, size: AnnotationSize, color: AnnotationColor, in ctx: CGContext
    ) {
        let diameter = size.markerDiameter
        let circle = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: circle)
        // Light colours need dark digits to stay readable.
        let digitColor: NSColor = (color == .yellow || color == .white) ? .black : .white
        let font = NSFont.systemFont(ofSize: diameter * 0.55, weight: .bold)
        let text = "\(number)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: digitColor]
        let measured = text.size(withAttributes: attributes)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        text.draw(
            at: CGPoint(x: center.x - measured.width / 2, y: center.y - measured.height / 2), withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// The shaft plus the two barbs of the arrow head.
    static func arrowSegments(from: CGPoint, to: CGPoint, lineWidth: CGFloat) -> [(CGPoint, CGPoint)] {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let length = hypot(to.x - from.x, to.y - from.y)
        let head = min(length * 0.5, 8 + lineWidth * 3)
        let spread = CGFloat.pi / 7
        func barb(_ offset: CGFloat) -> CGPoint {
            CGPoint(x: to.x - head * cos(angle + offset), y: to.y - head * sin(angle + offset))
        }
        return [(from, to), (to, barb(spread)), (to, barb(-spread))]
    }

    private static func drawText(
        _ string: String, at origin: CGPoint, size: AnnotationSize, color: AnnotationColor, in ctx: CGContext
    ) {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(color == .white ? 0.6 : 0.25)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: AnnotationText.font(size: size.fontSize),
            .foregroundColor: color.nsColor,
            .shadow: shadow,
        ]
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        (string as NSString).draw(at: origin, withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Hides `rect`: every block is reduced to its average colour, which destroys the detail underneath.
    /// Pixelate then shows the blocks as they are; blur smooths them. Both lose the same information,
    /// so neither can be reversed.
    private static func hide(
        _ rect: CGRect, in ctx: CGContext, source: CGImage, sourceOrigin: CGPoint, pointScale: CGFloat, smooth: Bool
    ) {
        let pixelRect = CGRect(
            x: (rect.minX - sourceOrigin.x) * pointScale, y: (rect.minY - sourceOrigin.y) * pointScale,
            width: rect.width * pointScale, height: rect.height * pointScale
        ).integral.intersection(CGRect(x: 0, y: 0, width: source.width, height: source.height))
        guard !pixelRect.isNull, pixelRect.width >= 1, pixelRect.height >= 1,
            let piece = source.cropping(to: pixelRect)
        else { return }

        // Average each block by shrinking the area to one pixel per block, then blow it back up
        // without smoothing so the blocks stay hard-edged.
        let blockPixels = pixelBlock * pointScale
        let smallWidth = max(1, Int((pixelRect.width / blockPixels).rounded(.up)))
        let smallHeight = max(1, Int((pixelRect.height / blockPixels).rounded(.up)))
        guard
            let small = CGContext(
                data: nil, width: smallWidth, height: smallHeight, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return }
        small.interpolationQuality = .high
        small.draw(piece, in: CGRect(x: 0, y: 0, width: smallWidth, height: smallHeight))
        guard let reduced = small.makeImage() else { return }

        let target = CGRect(
            x: sourceOrigin.x + pixelRect.minX / pointScale, y: sourceOrigin.y + pixelRect.minY / pointScale,
            width: pixelRect.width / pointScale, height: pixelRect.height / pointScale)
        // A smoothed enlargement fades at its rim, so draw it a little larger and clip to the area.
        let drawRect = smooth
            ? target.insetBy(dx: -target.width / CGFloat(smallWidth) / 2, dy: -target.height / CGFloat(smallHeight) / 2)
            : target
        ctx.saveGState()
        ctx.clip(to: target)
        ctx.interpolationQuality = smooth ? .high : .none
        // The context is y-down, so flip locally to draw the image upright.
        ctx.translateBy(x: drawRect.minX, y: drawRect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(reduced, in: CGRect(x: 0, y: 0, width: drawRect.width, height: drawRect.height))
        ctx.restoreGState()
    }
}

/// Bakes annotations into the cropped screenshot at its full pixel resolution.
enum AnnotatedImageExporter {
    /// - Parameters:
    ///   - cropped: the selection's pixels.
    ///   - annotations: in display-local points.
    ///   - cropOrigin: the top-left of `cropped` in display-local points.
    ///   - pointScale: pixels per point of the display.
    /// - Returns: `cropped` itself when there is nothing to draw; nil if the bitmap could not be made.
    static func render(
        cropped: CGImage, annotations: [Annotation], cropOrigin: CGPoint, pointScale: CGFloat
    ) -> CGImage? {
        guard !annotations.isEmpty else { return cropped }
        let space =
            cropped.colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let ctx = CGContext(
                data: nil, width: cropped.width, height: cropped.height, bitsPerComponent: 8, bytesPerRow: 0,
                space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height))
        // From here on, work in display points with a top-left origin.
        ctx.translateBy(x: 0, y: CGFloat(cropped.height))
        ctx.scaleBy(x: pointScale, y: -pointScale)
        ctx.translateBy(x: -cropOrigin.x, y: -cropOrigin.y)
        AnnotationRenderer.draw(
            annotations, in: ctx, source: cropped, sourceOrigin: cropOrigin, pointScale: pointScale)
        return ctx.makeImage()
    }
}
