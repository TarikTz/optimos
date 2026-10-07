import AppKit
import SwiftUI

/// Owns the optimizer window. Each time it is opened from scratch it starts a new session.
@MainActor
final class OptimizerWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var model: OptimizerViewModel?

    func show() {
        // A menu-bar-only app has no Dock icon or Cmd-Tab entry, so its window would get lost behind
        // other apps. While the window is open the app behaves like a normal app.
        NSApp.setActivationPolicy(.regular)
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let model = OptimizerViewModel()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Optimize Images"
        window.contentView = NSHostingView(rootView: OptimizerView(model: model))
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.model = model
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        model?.close()
        model = nil
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
