import Foundation

public struct PresetStore {
    public let url: URL
    public init(url: URL) { self.url = url }

    public static var defaultURL: URL {
        if let path = ProcessInfo.processInfo.environment["OPTIMOS_PRESETS_PATH"] {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Optimos/presets.json")
    }

    public func customPresets() throws -> [Preset] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([Preset].self, from: Data(contentsOf: url))
    }

    public func all() throws -> [Preset] { Preset.builtIns + (try customPresets()) }

    public func preset(named name: String) throws -> Preset? {
        try all().first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Replaces a custom preset of the same name. Built-in names are reserved.
    public func add(_ preset: Preset) throws {
        if Preset.builtIns.contains(where: { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }) {
            throw OptimosError.invalidOptions("'\(preset.name)' is a built-in preset name")
        }
        var custom = try customPresets().filter {
            $0.name.caseInsensitiveCompare(preset.name) != .orderedSame
        }
        custom.append(preset)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(custom).write(to: url, options: .atomic)
    }
}
