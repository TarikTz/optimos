import AppKit
import CoreGraphics
import Foundation
import ImageIO
import OptimosCore
import UniformTypeIdentifiers

protocol Pasteboard: Sendable {
    func writePNG(_ data: Data)
}

struct SystemPasteboard: Pasteboard {
    func writePNG(_ data: Data) {
        let board = NSPasteboard.general
        board.clearContents()
        board.setData(data, forType: .png)
    }
}

enum OutputError: Error, Equatable, CustomStringConvertible {
    case encodeFailed
    case cannotWrite(String)

    var description: String {
        switch self {
        case .encodeFailed: "could not encode the screenshot as PNG"
        case .cannotWrite(let why): "could not save the screenshot: \(why)"
        }
    }
}

enum PNGEncoder {
    static func data(from image: CGImage) throws -> Data {
        let out = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else {
            throw OutputError.encodeFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw OutputError.encodeFailed }
        return out as Data
    }
}

struct OutputResult: Equatable, Sendable {
    enum Destination: Equatable, Sendable {
        case clipboard
        case file(URL)
    }

    let destination: Destination
    let originalBytes: Int
    let finalBytes: Int
    /// Set when optimization failed and the unoptimized PNG was used instead.
    let warning: String?

    var toastMessage: String {
        let sizes = "\(Self.format(originalBytes)) → \(Self.format(finalBytes))"
        switch destination {
        case .clipboard:
            return warning.map { "Copied — \($0)" } ?? "Copied · \(sizes)"
        case .file(let url):
            let folder = url.deletingLastPathComponent().lastPathComponent
            let name = url.lastPathComponent
            return warning.map { "Saved to \(folder) · \(name) — \($0)" }
                ?? "Saved to \(folder) · \(name) · \(sizes)"
        }
    }

    private static func format(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

struct OutputService: Sendable {
    typealias Optimizer = @Sendable (Data) async throws -> Data

    var pasteboard: any Pasteboard
    /// Read at save time, so a folder chosen in the menu takes effect immediately.
    var saveDirectory: @Sendable () -> URL
    var optimizer: Optimizer
    var now: @Sendable () -> Date

    init(
        pasteboard: any Pasteboard = SystemPasteboard(),
        saveDirectory: @escaping @Sendable () -> URL = { SaveLocationStore.defaultDirectory },
        optimizer: @escaping Optimizer = OutputService.screenshotOptimizer,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.pasteboard = pasteboard
        self.saveDirectory = saveDirectory
        self.optimizer = optimizer
        self.now = now
    }

    /// OptimosCore's built-in Screenshot preset: lossless PNG, metadata stripped.
    static let screenshotOptimizer: Optimizer = { data in
        guard let preset = Preset.builtIns.first(where: { $0.name == "Screenshot" }) else {
            throw OptimosError.invalidOptions("built-in Screenshot preset is missing")
        }
        return try await preset.pipeline().run(data).bytes
    }

    func copy(_ image: CGImage) async throws -> OutputResult {
        let prepared = try await prepare(image)
        pasteboard.writePNG(prepared.bytes)
        return OutputResult(
            destination: .clipboard, originalBytes: prepared.originalBytes,
            finalBytes: prepared.bytes.count, warning: prepared.warning)
    }

    func save(_ image: CGImage) async throws -> OutputResult {
        let prepared = try await prepare(image)
        let url = try write(prepared.bytes)
        return OutputResult(
            destination: .file(url), originalBytes: prepared.originalBytes,
            finalBytes: prepared.bytes.count, warning: prepared.warning)
    }

    private struct Prepared {
        let bytes: Data
        let originalBytes: Int
        let warning: String?
    }

    /// Encodes to PNG and optimizes. If optimization fails the plain PNG is used and a warning is
    /// reported, so a screenshot is never lost and the problem is never silent.
    private func prepare(_ image: CGImage) async throws -> Prepared {
        let png = try PNGEncoder.data(from: image)
        do {
            return Prepared(bytes: try await optimizer(png), originalBytes: png.count, warning: nil)
        } catch {
            return Prepared(bytes: png, originalBytes: png.count, warning: "not optimized: \(error)")
        }
    }

    private func write(_ bytes: Data) throws -> URL {
        do {
            let directory = saveDirectory()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = ScreenshotFilename.make(for: now())
            let base = (name as NSString).deletingPathExtension
            var url = directory.appendingPathComponent(name)
            var counter = 2
            while FileManager.default.fileExists(atPath: url.path) {
                url = directory.appendingPathComponent("\(base) \(counter).png")
                counter += 1
            }
            try bytes.write(to: url, options: .atomic)
            return url
        } catch {
            throw OutputError.cannotWrite("\(error.localizedDescription)")
        }
    }
}
