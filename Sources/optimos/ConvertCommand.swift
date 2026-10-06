import ArgumentParser
import OptimosCore

struct ConvertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert an image to PNG, JPEG or WebP, optionally resizing.")

    @Argument(help: "Input image.") var file: String
    @Option(name: .long, help: "Target format: png, jpeg, webp.") var to: ImageFormat
    @Option(help: "Quality 1-100 (JPEG, lossy WebP).") var quality: Int?
    @Flag(help: "WebP: encode losslessly.") var lossless = false
    @Option(help: "Shrink to at most this width (keeps aspect ratio, never upscales).") var maxWidth: Int?
    @Option(help: "Shrink to at most this height.") var maxHeight: Int?
    @Option(help: "Background colour #RRGGBB for flattening transparency (needed for JPEG).") var background: String?
    @Option(name: .shortAndLong, help: "Output file. Default: next to the input with the new extension.")
    var output: String?
    @Flag(help: "Print machine-readable JSON.") var json = false

    func run() async throws {
        let preset = Preset(
            name: "convert", format: to, quality: quality, lossless: lossless,
            maxWidth: maxWidth, maxHeight: maxHeight, backgroundHex: background)
        let result = await processFile(
            file, pipeline: try preset.pipeline(), outputDirectory: nil, explicitOutput: output, suffix: "")
        try report([result], json: json)
    }
}
