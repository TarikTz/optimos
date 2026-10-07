import CoreGraphics

enum AnnotationHitTesting {
    /// The annotation under `point`, or nil. Shapes drawn on top win over the pixelated areas that
    /// are always rendered below them; among equals the most recently added wins.
    static func annotation(at point: CGPoint, in annotations: [Annotation]) -> Annotation? {
        let ordered = annotations.reversed()
        return ordered.first { !$0.isRedaction && hits($0, point) } ?? ordered.first { $0.isRedaction && hits($0, point) }
    }

    static func hits(_ annotation: Annotation, _ point: CGPoint) -> Bool {
        let tolerance = max(6, annotation.size.lineWidth + 3)
        switch annotation.kind {
        case .rectangle(let rect):
            return rect.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
                && !rect.insetBy(dx: tolerance, dy: tolerance).contains(point)
        case .ellipse(let rect):
            return inside(point, ellipseIn: rect.insetBy(dx: -tolerance, dy: -tolerance))
                && !inside(point, ellipseIn: rect.insetBy(dx: tolerance, dy: tolerance))
        case .arrow(let from, let to), .line(let from, let to):
            return distance(from: point, toSegment: from, to) <= tolerance
        case .marker(let center, _):
            return hypot(point.x - center.x, point.y - center.y) <= annotation.size.markerDiameter / 2 + 2
        case .text, .highlight, .pixelate, .blur:
            return annotation.bounds.contains(point)
        }
    }

    /// True if `point` is inside the ellipse inscribed in `rect` (false for a degenerate rect).
    static func inside(_ point: CGPoint, ellipseIn rect: CGRect) -> Bool {
        guard rect.width > 0, rect.height > 0 else { return false }
        let dx = (point.x - rect.midX) / (rect.width / 2)
        let dy = (point.y - rect.midY) / (rect.height / 2)
        return dx * dx + dy * dy <= 1
    }

    static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }
}
