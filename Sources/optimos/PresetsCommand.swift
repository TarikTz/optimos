import ArgumentParser
import Foundation
import OptimosCore

struct PresetsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "presets",
        abstract: "List, show and add presets.",
        subcommands: [List.self, Show.self, Add.self])

    struct List: ParsableCommand {
        func run() throws {
            for p in try PresetStore(url: PresetStore.defaultURL).all() {
                let size = [p.maxWidth.map { "max-width \($0)" }, p.maxHeight.map { "max-height \($0)" }]
                    .compactMap { $0 }.joined(separator: ", ")
                print("\(p.name): \(p.format?.rawValue ?? "same format")"
                    + (p.quality.map { " q\($0)" } ?? "") + (size.isEmpty ? "" : ", \(size)"))
            }
        }
    }

    struct Show: ParsableCommand {
        @Argument var name: String
        func run() throws {
            guard let p = try PresetStore(url: PresetStore.defaultURL).preset(named: name) else {
                throw ValidationError("unknown preset '\(name)'")
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            print(String(decoding: try encoder.encode(p), as: UTF8.self))
        }
    }

    struct Add: ParsableCommand {
        @Argument var name: String
        @Option var format: ImageFormat?
        @Option var quality: Int?
        @Option var maxWidth: Int?
        @Option var maxHeight: Int?
        @Flag var lossless = false
        @Flag(help: "Keep metadata instead of stripping it.") var keepMetadata = false
        @Option(help: "Background colour #RRGGBB for JPEG output.") var background: String?

        func run() throws {
            let preset = Preset(
                name: name, format: format, quality: quality, lossless: lossless,
                maxWidth: maxWidth, maxHeight: maxHeight, stripMetadata: !keepMetadata,
                backgroundHex: background)
            _ = try preset.pipeline()  // validates the background colour
            try PresetStore(url: PresetStore.defaultURL).add(preset)
            print("saved preset '\(name)'")
        }
    }
}
