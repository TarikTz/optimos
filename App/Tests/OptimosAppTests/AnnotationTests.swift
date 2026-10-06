import AppKit
import Testing

@testable import OptimosApp

@Suite struct AnnotationDocumentTests {
    private func rect(_ x: CGFloat = 0) -> Annotation {
        Annotation(kind: .rectangle(CGRect(x: x, y: 0, width: 10, height: 10)), color: .red, size: .medium)
    }

    @Test func addSelectsAndUndoRedoRoundTrips() {
        var doc = AnnotationDocument()
        let a = rect()
        doc.add(a)
        #expect(doc.annotations == [a])
        #expect(doc.selectedID == a.id)
        doc.undo()
        #expect(doc.isEmpty)
        #expect(doc.selectedID == nil)
        doc.redo()
        #expect(doc.annotations == [a])
    }

    @Test func newChangeClearsRedo() {
        var doc = AnnotationDocument()
        doc.add(rect())
        doc.undo()
        doc.add(rect(5))
        #expect(!doc.canRedo)
    }

    @Test func deleteAndRecolourAreUndoable() {
        var doc = AnnotationDocument()
        let a = rect()
        doc.add(a)
        doc.setColorOfSelected(.blue)
        #expect(doc.selected?.color == .blue)
        doc.undo()
        #expect(doc.selected?.color == .red)
        doc.deleteSelected()
        #expect(doc.isEmpty)
        doc.undo()
        #expect(doc.annotations == [a])
    }

    @Test func aWholeDragIsOneUndoStep() {
        var doc = AnnotationDocument()
        let a = rect()
        doc.add(a)
        doc.beginMove()
        doc.moveSelected(by: CGSize(width: 5, height: 0))
        doc.moveSelected(by: CGSize(width: 5, height: 0))
        #expect(doc.selected?.bounds.minX == 10)
        doc.undo()
        #expect(doc.annotations == [a])
    }

    @Test func clickWithoutMovingAddsNoUndoStep() {
        var doc = AnnotationDocument()
        doc.add(rect())
        doc.undo()
        doc.redo()
        doc.beginMove()
        #expect(!doc.canRedo)
        doc.undo()
        #expect(doc.isEmpty)  // one step back goes straight to before the add
    }
}

@Suite struct AnnotationHitTestingTests {
    @Test func rectangleIsHitOnItsEdgeNotItsMiddle() {
        let a = Annotation(kind: .rectangle(CGRect(x: 0, y: 0, width: 100, height: 100)), color: .red, size: .small)
        #expect(AnnotationHitTesting.hits(a, CGPoint(x: 50, y: 1)))
        #expect(!AnnotationHitTesting.hits(a, CGPoint(x: 50, y: 50)))
    }

    @Test func arrowIsHitNearItsLine() {
        let a = Annotation(kind: .arrow(from: .zero, to: CGPoint(x: 100, y: 0)), color: .red, size: .small)
        #expect(AnnotationHitTesting.hits(a, CGPoint(x: 50, y: 4)))
        #expect(!AnnotationHitTesting.hits(a, CGPoint(x: 50, y: 30)))
    }

    @Test func shapesWinOverPixelateBelowThem() {
        let hidden = Annotation(kind: .pixelate(CGRect(x: 0, y: 0, width: 100, height: 100)), color: .red, size: .small)
        let box = Annotation(kind: .rectangle(CGRect(x: 0, y: 0, width: 100, height: 100)), color: .red, size: .small)
        #expect(AnnotationHitTesting.annotation(at: CGPoint(x: 50, y: 1), in: [box, hidden])?.id == box.id)
        #expect(AnnotationHitTesting.annotation(at: CGPoint(x: 50, y: 50), in: [box, hidden])?.id == hidden.id)
    }
}

@Suite struct AnnotationRenderingTests {
    /// A 40×40 image with a left half of black and a right half of white pixels in a 1-px checker.
    private func checkerImage() -> CGImage {
        let ctx = CGContext(
            data: nil, width: 40, height: 40, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for y in 0..<40 {
            for x in 0..<40 {
                ctx.setFillColor(gray: (x + y) % 2 == 0 ? 0 : 1, alpha: 1)
                ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
        return ctx.makeImage()!
    }

    private func pixel(_ image: CGImage, _ x: Int, _ y: Int) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: 4)
        let ctx = CGContext(
            data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        return data
    }

    @Test func noAnnotationsReturnsTheSameImage() {
        let image = checkerImage()
        let out = AnnotatedImageExporter.render(cropped: image, annotations: [], cropOrigin: .zero, pointScale: 1)
        #expect(out === image)
    }

    @Test func pixelateRemovesTheDetailUnderneath() throws {
        let image = checkerImage()
        let hide = Annotation(kind: .pixelate(CGRect(x: 0, y: 0, width: 24, height: 24)), color: .red, size: .medium)
        let out = try #require(
            AnnotatedImageExporter.render(cropped: image, annotations: [hide], cropOrigin: .zero, pointScale: 1))
        #expect(out.width == 40 && out.height == 40)
        // Neighbouring pixels were black and white; inside one block they are now (nearly) the same grey.
        let a = pixel(out, 2, 2)[0]
        let b = pixel(out, 3, 2)[0]
        #expect(abs(Int(a) - Int(b)) < 8)
        // Outside the hidden area the checker is untouched.
        #expect(pixel(out, 30, 30)[0] != pixel(out, 31, 30)[0])
    }

    @Test func rectangleIsDrawnInItsColourAtTheRightPlace() throws {
        let image = checkerImage()
        let box = Annotation(kind: .rectangle(CGRect(x: 10, y: 10, width: 20, height: 20)), color: .red, size: .large)
        // Crop starts at (5,5) in display points; the box edge at x=10 lands at pixel 5 of the crop.
        let out = try #require(
            AnnotatedImageExporter.render(
                cropped: image, annotations: [box], cropOrigin: CGPoint(x: 5, y: 5), pointScale: 1))
        let p = pixel(out, 5, 15)
        #expect(p[0] > 200 && p[1] < 80 && p[2] < 80)
    }
}
