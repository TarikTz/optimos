import CoreGraphics
import Testing

@testable import OptimosApp

@Suite struct WindowPickerTests {
    // A second monitor to the LEFT of the primary has a negative global x origin.
    private let leftDisplay = DisplayInfo(id: 2, frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080))

    private func window(_ id: UInt32, _ frame: CGRect, layer: Int = 0) -> WindowInfo {
        WindowInfo(id: id, frame: frame, layer: layer, title: "w\(id)", appName: "App")
    }

    @Test func picksTheFirstWindowInFrontToBackOrder() {
        let front = window(1, CGRect(x: -1800, y: 100, width: 600, height: 400))
        let back = window(2, CGRect(x: -1900, y: 50, width: 1000, height: 800))
        // display-local (130, 110) is global (-1790, 110), inside both windows
        let picked = CaptureGeometry.topmostWindow(at: CGPoint(x: 130, y: 110), in: [front, back], display: leftDisplay)
        #expect(picked?.id == 1)
    }

    @Test func fallsThroughToTheWindowBehindWhenOutsideTheFrontOne() {
        let front = window(1, CGRect(x: -1800, y: 100, width: 600, height: 400))
        let back = window(2, CGRect(x: -1900, y: 50, width: 1000, height: 800))
        let picked = CaptureGeometry.topmostWindow(at: CGPoint(x: 50, y: 60), in: [front, back], display: leftDisplay)
        #expect(picked?.id == 2)
    }

    @Test func ignoresWindowsAboveTheNormalLayer() {
        let menuBar = window(1, CGRect(x: -1920, y: 0, width: 1920, height: 24), layer: 25)
        #expect(CaptureGeometry.topmostWindow(at: CGPoint(x: 10, y: 10), in: [menuBar], display: leftDisplay) == nil)
    }

    @Test func returnsNilWhenNoWindowIsUnderThePoint() {
        let small = window(1, CGRect(x: -1800, y: 100, width: 100, height: 100))
        #expect(CaptureGeometry.topmostWindow(at: CGPoint(x: 900, y: 900), in: [small], display: leftDisplay) == nil)
    }

    @Test func convertsAWindowToDisplayLocalPoints() {
        let w = window(1, CGRect(x: -1800, y: 100, width: 600, height: 400))
        #expect(CaptureGeometry.localRect(of: w, on: leftDisplay) == CGRect(x: 120, y: 100, width: 600, height: 400))
    }

    @Test func clipsAWindowThatHangsOffTheDisplay() {
        let w = window(1, CGRect(x: -2000, y: 100, width: 300, height: 200))
        #expect(CaptureGeometry.localRect(of: w, on: leftDisplay) == CGRect(x: 0, y: 100, width: 220, height: 200))
    }

    @Test func returnsNilForAWindowOnAnotherDisplay() {
        let w = window(1, CGRect(x: 100, y: 100, width: 300, height: 200))  // on the primary display
        #expect(CaptureGeometry.localRect(of: w, on: leftDisplay) == nil)
    }
}
