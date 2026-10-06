import AppKit
import Testing

@testable import OptimosApp

/// Stands in for the overlay view underneath the toolbar and counts what reaches it.
@MainActor
private final class CountingParent: NSView {
    var downs = 0
    var ups = 0
    var drags = 0
    var rightDowns = 0

    override func mouseDown(with event: NSEvent) { downs += 1 }
    override func mouseUp(with event: NSEvent) { ups += 1 }
    override func mouseDragged(with event: NSEvent) { drags += 1 }
    override func rightMouseDown(with event: NSEvent) { rightDowns += 1 }
}

@MainActor
@Suite struct OverlayToolbarTests {
    private func event(_ type: NSEvent.EventType) -> NSEvent {
        NSEvent.mouseEvent(
            with: type, location: NSPoint(x: 2, y: 2), modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
    }

    private func makeToolbarInParent() -> (OverlayToolbar, CountingParent) {
        let parent = CountingParent(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let toolbar = OverlayToolbar()
        parent.addSubview(toolbar)
        return (toolbar, parent)
    }

    @Test func leftMouseOnToolbarPaddingDoesNotReachTheView() {
        let (toolbar, parent) = makeToolbarInParent()
        toolbar.mouseDown(with: event(.leftMouseDown))
        toolbar.mouseDragged(with: event(.leftMouseDragged))
        toolbar.mouseUp(with: event(.leftMouseUp))
        #expect(parent.downs == 0)
        #expect(parent.drags == 0)
        #expect(parent.ups == 0)
    }

    @Test func rightMouseOnToolbarStillBubblesUpToCancel() {
        let (toolbar, parent) = makeToolbarInParent()
        toolbar.rightMouseDown(with: event(.rightMouseDown))
        #expect(parent.rightDowns == 1)
    }
}
