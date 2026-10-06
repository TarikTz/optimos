import ArgumentParser
import OptimosCore

struct OptimizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "optimize",
        abstract: "Losslessly optimize images, or apply a preset.")

    @Argument(help: "Image files (PNG, JPEG, WebP).") var files: [String]
    @Option(name: .shortAndLong, help: "Preset name (see `optimos presets list`).") var preset: String?
    @Option(name: .shortAndLong, help: "Output directory. Default: next to the input with an .optimized suffix.")
    var output: String?
    @Flag(help: "Print machine-readable JSON.") var json = false

    func run() async throws {
        let pipeline: Pipeline
        if let name = preset {
            guard let found = try PresetStore(url: PresetStore.defaultURL).preset(named: name) else {
                throw ValidationError("unknown preset '\(name)'")
            }
            pipeline = try found.pipeline()
        } else {
            pipeline = .defaultOptimize
        }
        var results: [FileResult] = []
        for file in files {
            results.append(await processFile(file, pipeline: pipeline, outputDirectory: output, suffix: ".optimized"))
        }
        try report(results, json: json)
    }
}
