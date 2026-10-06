import CoreGraphics

enum CaptureGeometry {
    /// Selections smaller than this (in points, either side) are treated as accidental clicks.
    static let minimumSelectionPoints: CGFloat = 4

    static func normalizedRect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    static func isAcceptable(_ rect: CGRect) -> Bool {
        rect.width >= minimumSelectionPoints && rect.height >= minimumSelectionPoints
    }

    /// Converts a rectangle in display-local points into a pixel rectangle on the frozen image,
    /// clamped to the image. Returns nil when nothing is left after clamping.
    static func pixelCropRect(for points: CGRect, displaySize: CGSize, imageSize: CGSize) -> CGRect? {
        guard displaySize.width > 0, displaySize.height > 0 else { return nil }
        let sx = imageSize.width / displaySize.width
        let sy = imageSize.height / displaySize.height
        let scaled = CGRect(
            x: points.minX * sx, y: points.minY * sy,
            width: points.width * sx, height: points.height * sy
        ).integral
        let clamped = scaled.intersection(CGRect(origin: .zero, size: imageSize))
        guard !clamped.isNull, clamped.width >= 1, clamped.height >= 1 else { return nil }
        return clamped
    }

    /// The front-most window under a display-local point. `windows` must be ordered front to back.
    static func topmostWindow(at point: CGPoint, in windows: [WindowInfo], display: DisplayInfo) -> WindowInfo? {
        let global = CGPoint(x: point.x + display.frame.minX, y: point.y + display.frame.minY)
        return windows.first { $0.layer == 0 && $0.frame.contains(global) }
    }

    /// The window's frame in display-local points, clipped to the display. Nil if it is not on this display.
    static func localRect(of window: WindowInfo, on display: DisplayInfo) -> CGRect? {
        let local = window.frame.offsetBy(dx: -display.frame.minX, dy: -display.frame.minY)
        let clipped = local.intersection(CGRect(origin: .zero, size: display.frame.size))
        return clipped.isNull || clipped.isEmpty ? nil : clipped
    }
}
