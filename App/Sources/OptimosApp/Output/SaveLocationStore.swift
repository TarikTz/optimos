import Foundation

/// Remembers where screenshots are saved and which file was saved last, in the app's preferences.
/// `UserDefaults` is documented as thread-safe, so sharing this value across tasks is safe.
struct SaveLocationStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private static let directoryKey = "saveDirectory"
    private static let lastFileKey = "lastSavedFile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// `~/Pictures/Optimos/`
    static var defaultDirectory: URL {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Optimos", isDirectory: true)
    }

    /// The chosen folder, or the default. A remembered folder that no longer exists is still returned
    /// (saving then reports a clear error) instead of silently substituting the default.
    var directory: URL {
        guard let path = defaults.string(forKey: Self.directoryKey), !path.isEmpty else {
            return Self.defaultDirectory
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    func setDirectory(_ url: URL) {
        defaults.set(url.path, forKey: Self.directoryKey)
    }

    /// The folder for display in the menu, e.g. `~/Pictures/Optimos`.
    var displayPath: String {
        (directory.path as NSString).abbreviatingWithTildeInPath
    }

    var lastSavedFile: URL? {
        defaults.string(forKey: Self.lastFileKey).map { URL(fileURLWithPath: $0) }
    }

    func setLastSavedFile(_ url: URL) {
        defaults.set(url.path, forKey: Self.lastFileKey)
    }
}
