import AppKit

extension NSScreen {
    /// The CoreGraphics display id, used to match an NSScreen to a ScreenCaptureKit display.
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    static func containingMouse() -> NSScreen? {
        let location = NSEvent.mouseLocation
        return screens.first { NSMouseInRect(location, $0.frame, false) }
    }
}
