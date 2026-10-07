import Foundation

/// The shortcut table: defaults, plus the user's own bindings, minus the actions they disabled.
struct HotkeyStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private static let bindingsKey = "hotkeyBindings"
    private static let disabledKey = "hotkeysDisabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var table: [HotkeyAction: Hotkey] {
        let custom = storedBindings
        let disabled = Set(defaults.stringArray(forKey: Self.disabledKey) ?? [])
        var result: [HotkeyAction: Hotkey] = [:]
        for action in HotkeyAction.allCases where !disabled.contains(String(action.rawValue)) {
            result[action] = custom[String(action.rawValue)] ?? Hotkey.defaults[action]
        }
        return result
    }

    func setTable(_ table: [HotkeyAction: Hotkey]) {
        var bindings: [String: Hotkey] = [:]
        var disabled: [String] = []
        for action in HotkeyAction.allCases {
            if let key = table[action] {
                if key != Hotkey.defaults[action] { bindings[String(action.rawValue)] = key }
            } else {
                disabled.append(String(action.rawValue))
            }
        }
        if let data = try? JSONEncoder().encode(bindings) { defaults.set(data, forKey: Self.bindingsKey) }
        defaults.set(disabled, forKey: Self.disabledKey)
    }

    private var storedBindings: [String: Hotkey] {
        defaults.data(forKey: Self.bindingsKey).flatMap { try? JSONDecoder().decode([String: Hotkey].self, from: $0) }
            ?? [:]
    }
}
