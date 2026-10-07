import CoreGraphics

/// A drag handle on a rectangle (eight) or on an arrow (its two ends).
enum ResizeHandle: Hashable, Sendable {
    case topLeft, topRight, bottomRight, bottomLeft, top, right, bottom, left
    case arrowStart, arrowEnd
}

/// Where handles sit and how dragging one changes a rectangle. Pure, so it can be unit-tested.
/// Shared by the capture selection and the annotations.
enum HandleGeometry {
    static let hitRadius: CGFloat = 8

    /// The eight handles of `rect`, corners first so they win where handles overlap on a small rect.
    static func positions(for rect: CGRect) -> [(handle: ResizeHandle, point: CGPoint)] {
        [
            (.topLeft, CGPoint(x: rect.minX, y: rect.minY)),
            (.topRight, CGPoint(x: rect.maxX, y: rect.minY)),
            (.bottomRight, CGPoint(x: rect.maxX, y: rect.maxY)),
            (.bottomLeft, CGPoint(x: rect.minX, y: rect.maxY)),
            (.top, CGPoint(x: rect.midX, y: rect.minY)),
            (.right, CGPoint(x: rect.maxX, y: rect.midY)),
            (.bottom, CGPoint(x: rect.midX, y: rect.maxY)),
            (.left, CGPoint(x: rect.minX, y: rect.midY)),
        ]
    }

    /// The first handle (in list order) within `hitRadius` of `point`.
    static func handle(at point: CGPoint, in positions: [(handle: ResizeHandle, point: CGPoint)]) -> ResizeHandle? {
        positions.first { hypot($0.point.x - point.x, $0.point.y - point.y) <= hitRadius }?.handle
    }

    /// `rect` with the dragged handle moved to `point` (kept inside `bounds`). The rectangle can never
    /// become smaller than `minSize` or flip over.
    static func resized(
        _ rect: CGRect, dragging handle: ResizeHandle, to point: CGPoint, minSize: CGFloat, within bounds: CGRect
    ) -> CGRect {
        let p = CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX), y: min(max(point.y, bounds.minY), bounds.maxY))
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        switch handle {
        case .topLeft, .bottomLeft, .left: minX = min(p.x, maxX - minSize)
        case .topRight, .bottomRight, .right: maxX = max(p.x, minX + minSize)
        default: break
        }
        switch handle {
        case .topLeft, .topRight, .top: minY = min(p.y, maxY - minSize)
        case .bottomLeft, .bottomRight, .bottom: maxY = max(p.y, minY + minSize)
        default: break
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension Annotation {
    /// Handles to show for this annotation (none for text, which only moves).
    var handlePositions: [(handle: ResizeHandle, point: CGPoint)] {
        switch kind {
        case .rectangle(let rect), .ellipse(let rect), .highlight(let rect), .pixelate(let rect), .blur(let rect):
            HandleGeometry.positions(for: rect)
        case .arrow(let from, let to), .line(let from, let to): [(.arrowStart, from), (.arrowEnd, to)]
        case .text, .marker: []
        }
    }

    /// The annotation with `handle` dragged to `point`, kept inside `bounds`.
    func resized(dragging handle: ResizeHandle, to point: CGPoint, within bounds: CGRect) -> Annotation {
        var copy = self
        switch kind {
        case .rectangle(let rect):
            copy.kind = .rectangle(HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds))
        case .ellipse(let rect):
            copy.kind = .ellipse(HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds))
        case .highlight(let rect):
            copy.kind = .highlight(HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds))
        case .pixelate(let rect):
            copy.kind = .pixelate(HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds))
        case .blur(let rect):
            copy.kind = .blur(HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds))
        case .arrow(let from, let to):
            let p = CGPoint(
                x: min(max(point.x, bounds.minX), bounds.maxX), y: min(max(point.y, bounds.minY), bounds.maxY))
            switch handle {
            case .arrowStart: copy.kind = .arrow(from: p, to: to)
            case .arrowEnd: copy.kind = .arrow(from: from, to: p)
            default: break
            }
        case .line(let from, let to):
            let p = CGPoint(
                x: min(max(point.x, bounds.minX), bounds.maxX), y: min(max(point.y, bounds.minY), bounds.maxY))
            switch handle {
            case .arrowStart: copy.kind = .line(from: p, to: to)
            case .arrowEnd: copy.kind = .line(from: from, to: p)
            default: break
            }
        case .text, .marker:
            break
        }
        return copy
    }
}
