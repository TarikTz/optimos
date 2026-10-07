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
    private let optimizerWindow = OptimizerWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests load the app as a host; do not register hotkeys or show UI there.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        NSApp.setActivationPolicy(.accessory)
        let permission = PermissionService()
        let saveLocation = SaveLocationStore()
        let coordinator = CaptureCoordinator(
            capture: ScreenCaptureKitService(), output: OutputService(saveDirectory: { saveLocation.directory }),
            permission: permission, toast: ToastPresenter(), overlay: SelectionOverlayController(),
            saveLocation: saveLocation)
        let menuBar = MenuBarController(permission: permission, saveLocation: saveLocation)
        let route: (HotkeyAction) -> Void = { [optimizerWindow] action in
            if action == .openOptimizer { optimizerWindow.show() } else { coordinator.perform(action) }
        }
        menuBar.onAction = route
        hotkeys.onAction = route
        menuBar.setFailedHotkeys(hotkeys.register(Hotkey.defaults))
        self.coordinator = coordinator
        self.menuBar = menuBar
    }
}
