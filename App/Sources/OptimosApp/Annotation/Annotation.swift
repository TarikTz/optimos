import AppKit
import CoreGraphics

enum AnnotationTool: Equatable, CaseIterable, Sendable {
    case select
    case rectangle
    case ellipse
    case arrow
    case line
    case text
    case highlight
    case marker
    case pixelate
    case blur
}

enum AnnotationColor: CaseIterable, Equatable, Sendable {
    case red, orange, yellow, green, blue, white

    var cgColor: CGColor {
        switch self {
        case .red: CGColor(srgbRed: 0.93, green: 0.18, blue: 0.16, alpha: 1)
        case .orange: CGColor(srgbRed: 1.0, green: 0.58, blue: 0.0, alpha: 1)
        case .yellow: CGColor(srgbRed: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        case .green: CGColor(srgbRed: 0.2, green: 0.78, blue: 0.35, alpha: 1)
        case .blue: CGColor(srgbRed: 0.0, green: 0.48, blue: 1.0, alpha: 1)
        case .white: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        }
    }

    var nsColor: NSColor { NSColor(cgColor: cgColor) ?? .red }
}

enum AnnotationSize: CaseIterable, Equatable, Sendable {
    case small, medium, large

    /// Stroke width in points for rectangles and arrows.
    var lineWidth: CGFloat {
        switch self {
        case .small: 2
        case .medium: 4
        case .large: 7
        }
    }

    /// Font size in points for text.
    var fontSize: CGFloat {
        switch self {
        case .small: 14
        case .medium: 20
        case .large: 30
        }
    }

    /// Diameter in points of a numbered marker.
    var markerDiameter: CGFloat {
        switch self {
        case .small: 22
        case .medium: 28
        case .large: 38
        }
    }
}

enum AnnotationKind: Equatable, Sendable {
    case rectangle(CGRect)
    case ellipse(CGRect)
    case arrow(from: CGPoint, to: CGPoint)
    case line(from: CGPoint, to: CGPoint)
    case text(origin: CGPoint, string: String)
    /// A translucent coloured band, like a highlighter pen.
    case highlight(CGRect)
    /// A numbered circle; `center` is in the same points as everything else.
    case marker(center: CGPoint, number: Int)
    case pixelate(CGRect)
    case blur(CGRect)
}

/// One drawn object, in display-local points (top-left origin), like `CaptureSelection`.
struct Annotation: Equatable, Identifiable, Sendable {
    let id: UUID
    var kind: AnnotationKind
    var color: AnnotationColor
    var size: AnnotationSize

    init(id: UUID = UUID(), kind: AnnotationKind, color: AnnotationColor, size: AnnotationSize) {
        self.id = id
        self.kind = kind
        self.color = color
        self.size = size
    }

    var isPixelate: Bool {
        if case .pixelate = kind { return true }
        return false
    }

    /// Pixelate and blur hide what is underneath; they always render below the other annotations.
    var isRedaction: Bool {
        switch kind {
        case .pixelate, .blur: true
        default: false
        }
    }

    func translated(by delta: CGSize) -> Annotation {
        var copy = self
        switch kind {
        case .rectangle(let rect): copy.kind = .rectangle(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .ellipse(let rect): copy.kind = .ellipse(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .highlight(let rect): copy.kind = .highlight(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .pixelate(let rect): copy.kind = .pixelate(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .blur(let rect): copy.kind = .blur(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .marker(let center, let number):
            copy.kind = .marker(center: CGPoint(x: center.x + delta.width, y: center.y + delta.height), number: number)
        case .arrow(let from, let to):
            copy.kind = .arrow(
                from: CGPoint(x: from.x + delta.width, y: from.y + delta.height),
                to: CGPoint(x: to.x + delta.width, y: to.y + delta.height))
        case .line(let from, let to):
            copy.kind = .line(
                from: CGPoint(x: from.x + delta.width, y: from.y + delta.height),
                to: CGPoint(x: to.x + delta.width, y: to.y + delta.height))
        case .text(let origin, let string):
            copy.kind = .text(
                origin: CGPoint(x: origin.x + delta.width, y: origin.y + delta.height), string: string)
        }
        return copy
    }

    /// The area the annotation occupies (used for the selection outline and text hit testing).
    var bounds: CGRect {
        switch kind {
        case .rectangle(let rect), .ellipse(let rect), .highlight(let rect), .pixelate(let rect), .blur(let rect): rect
        case .arrow(let from, let to), .line(let from, let to):
            CGRect(x: min(from.x, to.x), y: min(from.y, to.y), width: abs(from.x - to.x), height: abs(from.y - to.y))
        case .marker(let center, _):
            CGRect(
                x: center.x - size.markerDiameter / 2, y: center.y - size.markerDiameter / 2,
                width: size.markerDiameter, height: size.markerDiameter)
        case .text(let origin, let string):
            CGRect(origin: origin, size: AnnotationText.size(of: string, fontSize: size.fontSize))
        }
    }
}

enum AnnotationText {
    static func font(size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .semibold)
    }

    static func size(of string: String, fontSize: CGFloat) -> CGSize {
        let measured = (string as NSString).size(withAttributes: [.font: font(size: fontSize)])
        return CGSize(width: ceil(measured.width), height: ceil(measured.height))
    }
}
