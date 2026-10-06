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

/// True if `a` and `b` are (or would be) the same file: symlinks resolved, same inode when both exist,
/// or same parent directory with a case-insensitively equal name (errs on the safe side on case-sensitive volumes).
func isSameFile(_ a: URL, _ b: URL) -> Bool {
    func id(_ u: URL) -> NSObjectProtocol? {
        try? u.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier
    }
    let ra = a.resolvingSymlinksInPath().standardizedFileURL
    let rb = b.resolvingSymlinksInPath().standardizedFileURL
    if ra == rb { return true }
    if let ia = id(ra), let ib = id(rb), ia.isEqual(ib) { return true }
    let pa = ra.deletingLastPathComponent(), pb = rb.deletingLastPathComponent()
    let sameParent = pa == pb || { if let x = id(pa), let y = id(pb) { return x.isEqual(y) } else { return false } }()
    return sameParent && ra.lastPathComponent.caseInsensitiveCompare(rb.lastPathComponent) == .orderedSame
}

/// Key for spotting two outputs of one run that land on the same file: the parent directory's real
/// path (symlinks such as /tmp -> /private/tmp resolved) plus the file name, lowercased because
/// volumes are usually case-insensitive. Call once the parent directory exists. (`standardizedFileURL`
/// alone is not stable: it drops "/private" only once the path exists.)
func outputKey(_ url: URL) -> String {
    let parent = url.deletingLastPathComponent().standardizedFileURL.path
    var dir = parent
    if let real = realpath(parent, nil) {
        dir = String(cString: real)
        free(real)
    }
    return (dir as NSString).appendingPathComponent(url.lastPathComponent).lowercased()
}

/// Runs `pipeline` on one file and writes the result. Never overwrites the input, nor an output
/// written earlier in the same run (`claimedOutputs` holds their `outputKey`s and gains this one).
/// - `explicitOutput`: exact destination path.
/// - otherwise `outputDirectory` (same file name), or next to the input with `suffix`.
func processFile(
    _ path: String, pipeline: Pipeline, outputDirectory: String?, explicitOutput: String? = nil,
    suffix: String, claimedOutputs: inout Set<String>
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
        if isSameFile(dest, inURL) {
            throw ValidationError("refusing to overwrite the input file; choose a different output")
        }
        try FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        let key = outputKey(dest)
        if claimedOutputs.contains(key) {
            throw ValidationError("output would overwrite another output in this run: \(dest.path)")
        }
        try result.bytes.write(to: dest, options: .atomic)
        claimedOutputs.insert(key)
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
