import CoreGraphics
import Testing

@testable import OptimosApp

@Suite struct HandleGeometryTests {
    private let rect = CGRect(x: 100, y: 100, width: 200, height: 100)
    private let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

    @Test func hasEightHandlesAndFindsTheOneUnderThePointer() {
        let positions = HandleGeometry.positions(for: rect)
        #expect(positions.count == 8)
        #expect(HandleGeometry.handle(at: CGPoint(x: 103, y: 98), in: positions) == .topLeft)
        #expect(HandleGeometry.handle(at: CGPoint(x: 200, y: 102), in: positions) == .top)
        #expect(HandleGeometry.handle(at: CGPoint(x: 200, y: 150), in: positions) == nil)
    }

    @Test func draggingCornersAndEdgesMovesOnlyTheirSides() {
        func resize(_ h: ResizeHandle, _ x: CGFloat, _ y: CGFloat) -> CGRect {
            HandleGeometry.resized(rect, dragging: h, to: CGPoint(x: x, y: y), minSize: 4, within: bounds)
        }
        #expect(resize(.bottomRight, 400, 260) == CGRect(x: 100, y: 100, width: 300, height: 160))
        #expect(resize(.topLeft, 50, 40) == CGRect(x: 50, y: 40, width: 250, height: 160))
        #expect(resize(.right, 350, 999) == CGRect(x: 100, y: 100, width: 250, height: 100))
        #expect(resize(.top, 999, 60) == CGRect(x: 100, y: 60, width: 200, height: 140))
    }

    @Test func neverShrinksBelowTheMinimumFlipsOrLeavesTheBounds() {
        let tiny = HandleGeometry.resized(rect, dragging: .right, to: CGPoint(x: 10, y: 150), minSize: 4, within: bounds)
        #expect(tiny.width == 4 && tiny.minX == 100)
        let outside = HandleGeometry.resized(rect, dragging: .bottomRight, to: CGPoint(x: 5000, y: 5000), minSize: 4, within: bounds)
        #expect(outside.maxX == 800 && outside.maxY == 600)
    }
}

@Suite struct AnnotationResizeTests {
    private let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)

    @Test func rectanglesAndArrowsResizeButTextDoesNot() {
        let box = Annotation(kind: .rectangle(CGRect(x: 10, y: 10, width: 50, height: 50)), color: .red, size: .medium)
        let grown = box.resized(dragging: .bottomRight, to: CGPoint(x: 120, y: 90), within: bounds)
        #expect(grown.bounds == CGRect(x: 10, y: 10, width: 110, height: 80))

        let arrow = Annotation(kind: .arrow(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 100)), color: .red, size: .medium)
        let moved = arrow.resized(dragging: .arrowEnd, to: CGPoint(x: 999, y: 50), within: bounds)
        #expect(moved.kind == .arrow(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 400, y: 50)))

        let text = Annotation(kind: .text(origin: .zero, string: "Hi"), color: .red, size: .medium)
        #expect(text.handlePositions.isEmpty)
        #expect(text.resized(dragging: .topLeft, to: CGPoint(x: 5, y: 5), within: bounds) == text)
    }

    @Test func aWholeResizeDragIsOneUndoStep() {
        var doc = AnnotationDocument()
        let box = Annotation(kind: .rectangle(CGRect(x: 10, y: 10, width: 50, height: 50)), color: .red, size: .medium)
        doc.add(box)
        doc.beginMove()
        doc.resizeSelected(.bottomRight, to: CGPoint(x: 80, y: 80), within: bounds)
        doc.resizeSelected(.bottomRight, to: CGPoint(x: 120, y: 100), within: bounds)
        #expect(doc.selected?.bounds == CGRect(x: 10, y: 10, width: 110, height: 90))
        doc.undo()
        #expect(doc.annotations == [box])
    }
}
