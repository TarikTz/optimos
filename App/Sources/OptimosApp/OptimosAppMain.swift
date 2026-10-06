import AppKit
import SwiftUI

@main
struct OptimosAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests load the app as a host; do not show UI there.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "OptimosApp")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit OptimosApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }
}
