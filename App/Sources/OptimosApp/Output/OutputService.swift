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
    /// Turns PNG bytes into the output bytes for the given settings. Replaceable in tests.
    typealias Optimizer = @Sendable (Data, OptimizeSettings) async throws -> Data

    var pasteboard: any Pasteboard
    /// Read at save time, so a folder chosen in the menu takes effect immediately.
    var saveDirectory: @Sendable () -> URL
    /// Read at save time: the capture format (Save only; Copy is always PNG) and level.
    var captureSettings: @Sendable () -> (format: ImageFormat, level: OptimizeLevel)
    var optimizer: Optimizer
    var now: @Sendable () -> Date

    init(
        pasteboard: any Pasteboard = SystemPasteboard(),
        saveDirectory: @escaping @Sendable () -> URL = { SaveLocationStore.defaultDirectory },
        captureSettings: @escaping @Sendable () -> (format: ImageFormat, level: OptimizeLevel) = { (.png, .lossless) },
        optimizer: @escaping Optimizer = OutputService.screenshotOptimizer,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.pasteboard = pasteboard
        self.saveDirectory = saveDirectory
        self.captureSettings = captureSettings
        self.optimizer = optimizer
        self.now = now
    }

    /// OptimosCore's optimizer, with the chosen level and output format.
    static let screenshotOptimizer: Optimizer = { data, settings in
        try await settings.process(data).bytes
    }

    func copy(_ image: CGImage) async throws -> OutputResult {
        let prepared = try await prepare(image, format: .png)
        pasteboard.writePNG(prepared.bytes)
        return OutputResult(
            destination: .clipboard, originalBytes: prepared.originalBytes,
            finalBytes: prepared.bytes.count, warning: prepared.warning)
    }

    /// Saves into the configured folder with a timestamped name, or to `destination` when the user
    /// picked an exact file in a save panel.
    func save(_ image: CGImage, to destination: URL? = nil) async throws -> OutputResult {
        let format = captureSettings().format
        let prepared = try await prepare(image, format: format)
        // If optimizing failed the bytes are a plain PNG, so the file must say .png whatever was chosen.
        let actual: ImageFormat = prepared.isPlainPNG ? .png : format
        let fixedDestination = destination.map {
            $0.pathExtension.lowercased() == actual.fileExtension
                ? $0 : $0.deletingPathExtension().appendingPathExtension(actual.fileExtension)
        }
        let url = try fixedDestination.map { try writeExactly(prepared.bytes, to: $0) }
            ?? write(prepared.bytes, format: actual)
        return OutputResult(
            destination: .file(url), originalBytes: prepared.originalBytes,
            finalBytes: prepared.bytes.count, warning: prepared.warning)
    }

    private struct Prepared {
        let bytes: Data
        let originalBytes: Int
        let warning: String?
        var isPlainPNG = false
    }

    /// Encodes to PNG and optimizes. If optimization fails the plain PNG is used and a warning is
    /// reported, so a screenshot is never lost and the problem is never silent.
    private func prepare(_ image: CGImage, format: ImageFormat) async throws -> Prepared {
        let png = try PNGEncoder.data(from: image)
        do {
            let settings = OptimizeSettings(level: captureSettings().level, format: format)
            return Prepared(bytes: try await optimizer(png, settings), originalBytes: png.count, warning: nil)
        } catch {
            // The plain PNG is always usable; Save then writes it as a .png whatever the format setting.
            return Prepared(bytes: png, originalBytes: png.count, warning: "not optimized: \(error)", isPlainPNG: true)
        }
    }

    /// Only the default folder is created on demand; any other folder must already exist.
    static func requiresExistingFolder(_ directory: URL) -> Bool {
        directory.standardizedFileURL != SaveLocationStore.defaultDirectory.standardizedFileURL
    }

    /// The save panel already asked about overwriting, so this replaces the file.
    private func writeExactly(_ bytes: Data, to url: URL) throws -> URL {
        do {
            try bytes.write(to: url, options: .atomic)
            return url
        } catch {
            throw OutputError.cannotWrite("\(error.localizedDescription)")
        }
    }

    private func write(_ bytes: Data, format: ImageFormat) throws -> URL {
        do {
            let directory = saveDirectory()
            if Self.requiresExistingFolder(directory) {
                // Never recreate a remembered folder (e.g. an unplugged drive's mount point): that
                // would silently save somewhere other than the folder the user sees.
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) else {
                    throw OutputError.cannotWrite("the folder \(directory.path) does not exist")
                }
                guard isDirectory.boolValue else {
                    throw OutputError.cannotWrite("\(directory.path) is not a folder")
                }
            } else {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let name = ScreenshotFilename.make(for: now(), fileExtension: format.fileExtension)
            let base = (name as NSString).deletingPathExtension
            var url = directory.appendingPathComponent(name)
            var counter = 2
            while FileManager.default.fileExists(atPath: url.path) {
                url = directory.appendingPathComponent("\(base) \(counter).\(format.fileExtension)")
                counter += 1
            }
            try bytes.write(to: url, options: .atomic)
            return url
        } catch let error as OutputError {
            throw error
        } catch {
            throw OutputError.cannotWrite("\(error.localizedDescription)")
        }
    }
}
