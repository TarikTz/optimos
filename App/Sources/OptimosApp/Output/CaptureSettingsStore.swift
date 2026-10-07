import Foundation
import OptimosCore

/// Format and optimization level for screenshots. The format applies to Save; Copy is always PNG.
struct CaptureSettingsStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private static let formatKey = "captureFormat"
    private static let levelKey = "captureLevel"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var format: ImageFormat {
        get { defaults.string(forKey: Self.formatKey).flatMap(ImageFormat.init(rawValue:)) ?? .png }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.formatKey) }
    }

    var level: OptimizeLevel {
        get { defaults.string(forKey: Self.levelKey).flatMap(OptimizeLevel.init(rawValue:)) ?? .lossless }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.levelKey) }
    }
}
