import Foundation
import Observation
import OptimosCore

/// The Preferences window's state. Every change is written to its store straight away.
@MainActor
@Observable
final class PreferencesModel {
    var asksWhereToSave: Bool { didSet { saveLocation.setAsksWhereToSave(asksWhereToSave) } }
    private(set) var saveDirectory: URL
    var optimizer: OptimizeSettings { didSet { optimizerStore.settings = optimizer } }
    var captureFormat: ImageFormat { didSet { captureStore.format = captureFormat } }
    var captureLevel: OptimizeLevel { didSet { captureStore.level = captureLevel } }
    var captureMaxSide: Int? { didSet { captureStore.maxSide = captureMaxSide } }
    private(set) var hotkeys: [HotkeyAction: Hotkey]
    private(set) var hotkeyErrors: [HotkeyAction: String] = [:]
    private(set) var launchAtLogin: Bool
    private(set) var launchAtLoginError: String?

    @ObservationIgnored private let saveLocation: SaveLocationStore
    @ObservationIgnored private let optimizerStore: OptimizerSettingsStore
    @ObservationIgnored private let captureStore: CaptureSettingsStore
    @ObservationIgnored private let hotkeyStore: HotkeyStore
    /// Registers a whole shortcut table and returns the actions that could not be registered.
    @ObservationIgnored private let applyHotkeys: ([HotkeyAction: Hotkey]) -> [HotkeyAction]

    init(
        saveLocation: SaveLocationStore, optimizerStore: OptimizerSettingsStore = OptimizerSettingsStore(),
        captureStore: CaptureSettingsStore, hotkeyStore: HotkeyStore = HotkeyStore(),
        applyHotkeys: @escaping ([HotkeyAction: Hotkey]) -> [HotkeyAction]
    ) {
        self.saveLocation = saveLocation
        self.optimizerStore = optimizerStore
        self.captureStore = captureStore
        self.hotkeyStore = hotkeyStore
        self.applyHotkeys = applyHotkeys
        asksWhereToSave = saveLocation.asksWhereToSave
        saveDirectory = saveLocation.directory
        optimizer = optimizerStore.settings
        captureFormat = captureStore.format
        captureLevel = captureStore.level
        captureMaxSide = captureStore.maxSide
        hotkeys = hotkeyStore.table
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    func setSaveDirectory(_ url: URL) {
        saveLocation.setDirectory(url)
        saveDirectory = url
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.set(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "macOS did not allow that: \(error.localizedDescription)"
        }
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    /// Sets, replaces or (with nil) disables the shortcut of one action. The old table is restored
    /// if the new combination cannot be registered.
    func setHotkey(_ key: Hotkey?, for action: HotkeyAction) {
        hotkeyErrors[action] = nil
        var candidate = hotkeys
        candidate[action] = key
        if let key, let error = ShortcutValidator.validate(key, for: action, in: hotkeys) {
            hotkeyErrors[action] = error.message
            return
        }
        if applyHotkeys(candidate).contains(action), key != nil {
            _ = applyHotkeys(hotkeys)
            hotkeyErrors[action] = "That shortcut is already in use by macOS or another app."
            return
        }
        hotkeys = candidate
        hotkeyStore.setTable(candidate)
    }

    func resetHotkey(_ action: HotkeyAction) {
        setHotkey(Hotkey.defaults[action], for: action)
    }
}
