import AppKit
import CoreGraphics

enum AnnotationTool: Equatable, CaseIterable, Sendable {
    case select
    case rectangle
    case arrow
    case text
    case pixelate
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
}

enum AnnotationKind: Equatable, Sendable {
    case rectangle(CGRect)
    case arrow(from: CGPoint, to: CGPoint)
    case text(origin: CGPoint, string: String)
    case pixelate(CGRect)
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

    func translated(by delta: CGSize) -> Annotation {
        var copy = self
        switch kind {
        case .rectangle(let rect): copy.kind = .rectangle(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .pixelate(let rect): copy.kind = .pixelate(rect.offsetBy(dx: delta.width, dy: delta.height))
        case .arrow(let from, let to):
            copy.kind = .arrow(
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
        case .rectangle(let rect), .pixelate(let rect): rect
        case .arrow(let from, let to):
            CGRect(x: min(from.x, to.x), y: min(from.y, to.y), width: abs(from.x - to.x), height: abs(from.y - to.y))
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
