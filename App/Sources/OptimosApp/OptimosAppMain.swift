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
    private var preferencesWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests load the app as a host; do not register hotkeys or show UI there.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        NSApp.setActivationPolicy(.accessory)
        OutputService.clearShareDirectory()
        let permission = PermissionService()
        let saveLocation = SaveLocationStore()
        let captureSettings = CaptureSettingsStore()
        let coordinator = CaptureCoordinator(
            capture: ScreenCaptureKitService(), output: OutputService(
                saveDirectory: { saveLocation.directory },
                captureSettings: { (captureSettings.format, captureSettings.level, captureSettings.maxSide) }),
            permission: permission, toast: ToastPresenter(), overlay: SelectionOverlayController(),
            saveLocation: saveLocation, captureSettings: captureSettings)
        let hotkeyStore = HotkeyStore()
        let menuBar = MenuBarController(
            permission: permission, saveLocation: saveLocation, hotkeys: { hotkeyStore.table })
        let route: (HotkeyAction) -> Void = { [optimizerWindow] action in
            if action == .openOptimizer { optimizerWindow.show() } else { coordinator.perform(action) }
        }
        menuBar.onAction = route
        hotkeys.onAction = route
        menuBar.setFailedHotkeys(hotkeys.register(hotkeyStore.table))
        let preferences = PreferencesWindowController(makeModel: { [hotkeys] in
            PreferencesModel(
                saveLocation: saveLocation, captureStore: captureSettings, hotkeyStore: hotkeyStore,
                applyHotkeys: { table in
                    let failed = hotkeys.register(table)
                    menuBar.setFailedHotkeys(failed)
                    return failed
                })
        })
        menuBar.onOpenPreferences = { preferences.show() }
        menuBar.onAbout = { AboutPanel.show() }
        preferencesWindow = preferences
        self.coordinator = coordinator
        self.menuBar = menuBar
    }
}
