import Foundation
import OptimosCore

/// The optimizer's settings, shared by the optimizer window's bar and the Preferences tab.
struct OptimizerSettingsStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private static let key = "optimizerSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Falls back to the defaults when nothing is stored or the stored data cannot be read.
    var settings: OptimizeSettings {
        get {
            defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(OptimizeSettings.self, from: $0) }
                ?? OptimizeSettings()
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: Self.key) }
        }
    }
}
