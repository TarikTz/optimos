import CoreGraphics
import Testing

@testable import OptimosApp

@Suite struct ToolbarPlacementTests {
    private let toolbar = CGSize(width: 124, height: 36)
    private let display = CGSize(width: 1440, height: 900)

    private func place(_ selection: CGRect, in size: CGSize? = nil) -> CGRect {
        ToolbarPlacement.frame(for: selection, toolbarSize: toolbar, displaySize: size ?? display)
    }

    @Test func sitsBelowTheSelectionAtItsRightEdge() {
        // selection right edge is x = 400, so the toolbar spans 276...400; 8pt below the bottom (300)
        #expect(place(CGRect(x: 100, y: 100, width: 300, height: 200)) == CGRect(x: 276, y: 308, width: 124, height: 36))
    }

    @Test func flipsAboveWhenThereIsNoRoomBelow() {
        // bottom edge at 880 leaves no room for 8 + 36 under it on a 900pt display
        #expect(place(CGRect(x: 100, y: 800, width: 300, height: 80)) == CGRect(x: 276, y: 756, width: 124, height: 36))
    }

    @Test func goesInsideTheBottomRightWhenThereIsNoRoomOutside() {
        // a full-screen selection: nothing below or above, so inside, clamped to the display margin
        #expect(place(CGRect(x: 0, y: 0, width: 1440, height: 900)) == CGRect(x: 1312, y: 856, width: 124, height: 36))
    }

    @Test func staysInsideTheDisplayAtTheLeftEdge() {
        // a narrow selection at the left edge would put the toolbar at a negative x
        #expect(place(CGRect(x: 0, y: 100, width: 50, height: 50)).minX == ToolbarPlacement.margin)
    }

    @Test func staysInsideTheDisplayAtTheRightEdge() {
        let frame = place(CGRect(x: 1400, y: 100, width: 40, height: 40))
        #expect(frame.maxX <= display.width - ToolbarPlacement.margin)
    }

    @Test func fitsOnASmallDisplay() {
        let small = CGSize(width: 300, height: 200)
        let frame = place(CGRect(x: 20, y: 20, width: 260, height: 160), in: small)
        #expect(CGRect(origin: .zero, size: small).contains(frame))
    }
}
