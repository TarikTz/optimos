import Carbon.HIToolbox
import Foundation

enum ShortcutError: Equatable {
    case needsModifier
    case duplicate(HotkeyAction)
    case reserved

    var message: String {
        switch self {
        case .needsModifier: "Include ⌃, ⌥ or ⌘ so typing cannot trigger it."
        case .duplicate(let other): "Already used by \(other.menuTitle)."
        case .reserved: "macOS uses that combination."
        }
    }
}

enum ShortcutValidator {
    private static let reserved: [(modifiers: UInt32, keyCodes: Set<Int>)] = [
        (UInt32(cmdKey), [kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_H, kVK_Space, kVK_Tab]),
        (UInt32(cmdKey | shiftKey), [kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5]),
    ]

    /// Why `key` cannot be used for `action`, or nil if it can.
    static func validate(_ key: Hotkey, for action: HotkeyAction, in table: [HotkeyAction: Hotkey]) -> ShortcutError? {
        if key.modifiers & UInt32(controlKey | optionKey | cmdKey) == 0 { return .needsModifier }
        if reserved.contains(where: { $0.modifiers == key.modifiers && $0.keyCodes.contains(Int(key.keyCode)) }) {
            return .reserved
        }
        if let other = table.first(where: { $0.key != action && $0.value.keyCode == key.keyCode && $0.value.modifiers == key.modifiers })?.key {
            return .duplicate(other)
        }
        return nil
    }
}
