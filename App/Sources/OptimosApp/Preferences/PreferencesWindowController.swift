import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let makeModel: () -> PreferencesModel

    init(makeModel: @escaping () -> PreferencesModel) {
        self.makeModel = makeModel
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "OptimosApp Preferences"
            window.contentView = NSHostingView(rootView: PreferencesView(model: makeModel()))
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
            AppPresence.windowOpened()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        AppPresence.windowClosed()
    }
}
