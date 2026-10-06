import CoreGraphics
import Testing

@testable import OptimosApp

@Suite struct CaptureGeometryTests {
    @Test func normalizesADragInAnyDirection() {
        let rect = CaptureGeometry.normalizedRect(from: CGPoint(x: 50, y: 40), to: CGPoint(x: 10, y: 10))
        #expect(rect == CGRect(x: 10, y: 10, width: 40, height: 30))
    }

    @Test func rejectsAccidentalClicks() {
        #expect(!CaptureGeometry.isAcceptable(CGRect(x: 0, y: 0, width: 3, height: 100)))
        #expect(!CaptureGeometry.isAcceptable(CGRect(x: 0, y: 0, width: 100, height: 3)))
        #expect(CaptureGeometry.isAcceptable(CGRect(x: 0, y: 0, width: 4, height: 4)))
    }

    @Test func scalesPointsToPixelsOnRetina() {
        let crop = CaptureGeometry.pixelCropRect(
            for: CGRect(x: 10, y: 20, width: 100, height: 50),
            displaySize: CGSize(width: 1440, height: 900), imageSize: CGSize(width: 2880, height: 1800))
        #expect(crop == CGRect(x: 20, y: 40, width: 200, height: 100))
    }

    @Test func keepsPointsAsPixelsOnANonRetinaDisplay() {
        let crop = CaptureGeometry.pixelCropRect(
            for: CGRect(x: 10, y: 20, width: 100, height: 50),
            displaySize: CGSize(width: 1920, height: 1080), imageSize: CGSize(width: 1920, height: 1080))
        #expect(crop == CGRect(x: 10, y: 20, width: 100, height: 50))
    }

    @Test func clampsASelectionThatRunsOffTheDisplay() {
        let crop = CaptureGeometry.pixelCropRect(
            for: CGRect(x: 1400, y: 880, width: 100, height: 100),
            displaySize: CGSize(width: 1440, height: 900), imageSize: CGSize(width: 2880, height: 1800))
        #expect(crop == CGRect(x: 2800, y: 1760, width: 80, height: 40))
    }

    @Test func returnsNilWhenNothingIsLeft() {
        let size = CGSize(width: 100, height: 100)
        #expect(CaptureGeometry.pixelCropRect(for: CGRect(x: 200, y: 200, width: 10, height: 10), displaySize: size, imageSize: size) == nil)
        #expect(CaptureGeometry.pixelCropRect(for: CGRect(x: 10, y: 10, width: 0, height: 10), displaySize: size, imageSize: size) == nil)
        #expect(CaptureGeometry.pixelCropRect(for: CGRect(x: 0, y: 0, width: 10, height: 10), displaySize: .zero, imageSize: size) == nil)
    }

    @Test func roundsOutwardToWholePixels() {
        let crop = CaptureGeometry.pixelCropRect(
            for: CGRect(x: 10.25, y: 10.25, width: 10.3, height: 10.3),
            displaySize: CGSize(width: 100, height: 100), imageSize: CGSize(width: 200, height: 200))
        #expect(crop == CGRect(x: 20, y: 20, width: 22, height: 22))
    }
}
