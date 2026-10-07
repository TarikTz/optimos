import AppKit

/// A menu-bar-only app has no Dock icon or Cmd-Tab entry, so a window would get lost behind other
/// apps. While any of our windows is open the app behaves like a normal app.
@MainActor
enum AppPresence {
    private static var openWindows = 0

    static func windowOpened() {
        openWindows += 1
        NSApp.setActivationPolicy(.regular)
    }

    static func windowClosed() {
        openWindows = max(0, openWindows - 1)
        if openWindows == 0 { NSApp.setActivationPolicy(.accessory) }
    }
}
