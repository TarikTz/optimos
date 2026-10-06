import AppKit
import OSLog
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
    private let hotkeys = HotkeyManager()
    private var menuBar: MenuBarController?
    private let log = Logger(subsystem: "app.optimos.OptimosApp", category: "actions")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests load the app as a host; do not register hotkeys or show UI there.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        NSApp.setActivationPolicy(.accessory)
        let menuBar = MenuBarController(permission: PermissionService())
        let handle: (HotkeyAction) -> Void = { [log] action in
            log.info("action requested: \(action.rawValue, privacy: .public)")
        }
        menuBar.onAction = handle
        hotkeys.onAction = handle
        menuBar.setFailedHotkeys(hotkeys.register(Hotkey.defaults))
        self.menuBar = menuBar
    }
}
