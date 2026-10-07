import Foundation
import OptimosCore

/// Format and optimization level for screenshots. The format applies to Save; Copy is always PNG.
struct CaptureSettingsStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private static let formatKey = "captureFormat"
    private static let levelKey = "captureLevel"
    private static let maxSideKey = "captureMaxSide"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var format: ImageFormat {
        get { defaults.string(forKey: Self.formatKey).flatMap(ImageFormat.init(rawValue:)) ?? .png }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.formatKey) }
    }

    /// Longest side in pixels for captures; nil keeps the original size.
    var maxSide: Int? {
        get { defaults.object(forKey: Self.maxSideKey) as? Int }
        nonmutating set {
            if let newValue { defaults.set(newValue, forKey: Self.maxSideKey) } else { defaults.removeObject(forKey: Self.maxSideKey) }
        }
    }

    var level: OptimizeLevel {
        get { defaults.string(forKey: Self.levelKey).flatMap(OptimizeLevel.init(rawValue:)) ?? .lossless }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.levelKey) }
    }
}
