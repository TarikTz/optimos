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
    private let hotkeys = HotkeyManager()
    private var menuBar: MenuBarController?
    private var coordinator: CaptureCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests load the app as a host; do not register hotkeys or show UI there.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        NSApp.setActivationPolicy(.accessory)
        let permission = PermissionService()
        let saveLocation = SaveLocationStore()
        let coordinator = CaptureCoordinator(
            capture: ScreenCaptureKitService(), output: OutputService(saveDirectory: { saveLocation.directory }),
            permission: permission, toast: ToastPresenter(), overlay: SelectionOverlayController())
        let menuBar = MenuBarController(permission: permission, saveLocation: saveLocation)
        menuBar.onAction = { coordinator.perform($0) }
        hotkeys.onAction = { coordinator.perform($0) }
        menuBar.setFailedHotkeys(hotkeys.register(Hotkey.defaults))
        self.coordinator = coordinator
        self.menuBar = menuBar
    }
}
