import Carbon.HIToolbox
import Foundation

enum HotkeyAction: UInt32, CaseIterable, Sendable {
    case captureArea = 1
    case captureScreen = 2

    var menuTitle: String {
        switch self {
        case .captureArea: "Capture Area or Window"
        case .captureScreen: "Capture Screen"
        }
    }
}

struct Hotkey: Equatable, Sendable {
    let keyCode: UInt32
    /// Carbon modifier mask (controlKey | optionKey | cmdKey | shiftKey).
    let modifiers: UInt32
    let keyLabel: String

    var displayString: String {
        var text = ""
        if modifiers & UInt32(controlKey) != 0 { text += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { text += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { text += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { text += "⌘" }
        return text + keyLabel
    }

    private static let controlOptionCommand = UInt32(controlKey | optionKey | cmdKey)

    /// Defaults avoid macOS's own ⌘⇧3/4/5 screenshot shortcuts so they work on first launch.
    static let defaults: [HotkeyAction: Hotkey] = [
        .captureArea: Hotkey(keyCode: UInt32(kVK_ANSI_4), modifiers: controlOptionCommand, keyLabel: "4"),
        .captureScreen: Hotkey(keyCode: UInt32(kVK_ANSI_3), modifiers: controlOptionCommand, keyLabel: "3"),
    ]
}

@MainActor
final class HotkeyManager {
    /// The Carbon callback is a C function and cannot capture context, so it reaches us through this.
    static weak var current: HotkeyManager?

    var onAction: ((HotkeyAction) -> Void)?

    private var references: [HotkeyAction: EventHotKeyRef] = [:]
    private var handlerInstalled = false
    private let signature = OSType(0x4F50_5431)  // 'OPT1'

    /// Registers every hotkey and returns the actions that could not be registered
    /// (for example because another app already owns the combination).
    func register(_ table: [HotkeyAction: Hotkey]) -> [HotkeyAction] {
        unregisterAll()
        guard installHandlerIfNeeded() else {
            return table.keys.sorted { $0.rawValue < $1.rawValue }
        }
        HotkeyManager.current = self
        var failed: [HotkeyAction] = []
        for (action, key) in table {
            var reference: EventHotKeyRef?
            let id = EventHotKeyID(signature: signature, id: action.rawValue)
            let status = RegisterEventHotKey(
                key.keyCode, key.modifiers, id, GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference {
                references[action] = reference
            } else {
                failed.append(action)
            }
        }
        return failed.sorted { $0.rawValue < $1.rawValue }
    }

    func unregisterAll() {
        for reference in references.values { UnregisterEventHotKey(reference) }
        references.removeAll()
    }

    /// Installs the Carbon event handler. Replaceable so tests can simulate a failure
    /// without touching real global hotkeys.
    var handlerInstaller: @MainActor () -> OSStatus = {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        return InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var id = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
                guard status == noErr, let action = HotkeyAction(rawValue: id.id) else {
                    return OSStatus(eventNotHandledErr)
                }
                Task { @MainActor in HotkeyManager.current?.onAction?(action) }
                return noErr
            }, 1, &spec, nil, nil)
    }

    private func installHandlerIfNeeded() -> Bool {
        if handlerInstalled { return true }
        if handlerInstaller() == noErr { handlerInstalled = true }
        return handlerInstalled
    }
}
