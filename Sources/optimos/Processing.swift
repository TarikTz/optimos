import ArgumentParser
import Foundation
import OptimosCore

extension ImageFormat: ExpressibleByArgument {
    public init?(argument: String) { self.init(name: argument) }
}

struct FileResult: Codable {
    let input: String
    let output: String?
    let format: String?
    let originalBytes: Int?
    let newBytes: Int?
    let savedPercent: Double?
    let error: String?
}

func formatBytes(_ n: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
}

/// Runs `pipeline` on one file and writes the result. Never overwrites the input.
/// - `explicitOutput`: exact destination path.
/// - otherwise `outputDirectory` (same file name), or next to the input with `suffix`.
func processFile(
    _ path: String, pipeline: Pipeline, outputDirectory: String?, explicitOutput: String? = nil,
    suffix: String
) async -> FileResult {
    do {
        let inURL = URL(fileURLWithPath: path)
        let result = try await pipeline.run(Data(contentsOf: inURL))
        let base = inURL.deletingPathExtension().lastPathComponent
        let ext = result.format.fileExtension
        let dest: URL
        if let explicitOutput {
            dest = URL(fileURLWithPath: explicitOutput)
        } else if let dir = outputDirectory {
            dest = URL(fileURLWithPath: dir, isDirectory: true).appendingPathComponent("\(base).\(ext)")
        } else {
            dest = inURL.deletingLastPathComponent().appendingPathComponent("\(base)\(suffix).\(ext)")
        }
        if dest.standardizedFileURL == inURL.standardizedFileURL {
            throw ValidationError("refusing to overwrite the input file; choose a different output")
        }
        try FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try result.bytes.write(to: dest, options: .atomic)
        return FileResult(
            input: path, output: dest.path, format: result.format.rawValue,
            originalBytes: result.originalSize, newBytes: result.newSize,
            savedPercent: (result.savedFraction * 1000).rounded() / 10, error: nil)
    } catch {
        return FileResult(
            input: path, output: nil, format: nil, originalBytes: nil, newBytes: nil,
            savedPercent: nil, error: "\(error)")
    }
}

/// Prints results and returns normally; throws ExitCode.failure if any file failed.
func report(_ results: [FileResult], json: Bool) throws {
    if json {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(decoding: try encoder.encode(results), as: UTF8.self))
    } else {
        for r in results {
            if let error = r.error {
                FileHandle.standardError.write(Data("error: \(r.input): \(error)\n".utf8))
            } else if let out = r.output, let old = r.originalBytes, let new = r.newBytes, let pct = r.savedPercent {
                print("\(r.input) → \(out)  \(formatBytes(old)) → \(formatBytes(new))  saved \(pct)%")
            }
        }
    }
    if results.contains(where: { $0.error != nil }) { throw ExitCode.failure }
}
