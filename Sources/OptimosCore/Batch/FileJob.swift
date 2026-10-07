import Foundation
import ImageIO

public struct FileJobResult: Equatable, Sendable {
    public enum Outcome: Equatable, Sendable {
        /// Same format: the file was overwritten with the result.
        case replaced
        /// Same format: nothing smaller was possible, the file is untouched.
        case alreadyOptimal
        /// A new file was written (a conversion, or a copy when originals are kept); the original is untouched.
        case converted(output: URL)
    }

    public let source: URL
    public let outcome: Outcome
    public let originalBytes: Int
    public let newBytes: Int

    public var savedFraction: Double {
        originalBytes == 0 ? 0 : Double(originalBytes - newBytes) / Double(originalBytes)
    }
}

public enum FileJob {
    /// Optimizes one file.
    /// - Parameter willReplace: called with the file's URL right before it is overwritten (the app
    ///   backs the original up here). If it throws, the file is not touched.
    public static func run(
        _ url: URL, settings: OptimizeSettings, willReplace: @Sendable (URL) throws -> Void = { _ in }
    ) async throws -> FileJobResult {
        let original = try Data(contentsOf: url)
        var input = original
        var settings = settings
        var inputFormat: ImageFormat
        var isConvertibleOnly = false  // HEIC, TIFF, BMP: never replaced, always converted
        if let sniffed = ImageFormat.sniff(original) {
            inputFormat = sniffed
        } else if let decoded = try ConvertibleInput.decode(original) {
            input = decoded.png
            inputFormat = .png
            isConvertibleOnly = true
            if settings.format == nil { settings.format = decoded.defaultTarget }
        } else {
            throw OptimosError.unsupportedFormat
        }
        let willShrink = settings.willShrink(input)
        let result = try await settings.pipeline(inputFormat: inputFormat, willShrink: willShrink).run(input)

        if result.format == inputFormat && !isConvertibleOnly {
            // A requested shrink counts even if the bytes did not drop; otherwise only a smaller file wins.
            guard result.newSize < result.originalSize || willShrink else {
                return FileJobResult(
                    source: url, outcome: .alreadyOptimal, originalBytes: original.count, newBytes: original.count)
            }
            if !settings.replaceOriginals {
                let output = try writeNew(result.bytes, besides: url, suffix: "-optimized", format: result.format)
                return FileJobResult(
                    source: url, outcome: .converted(output: output), originalBytes: original.count,
                    newBytes: result.newSize)
            }
            try willReplace(url)
            try replace(url, with: result.bytes)
            return FileJobResult(
                source: url, outcome: .replaced, originalBytes: original.count, newBytes: result.newSize)
        }
        let output = try writeNew(result.bytes, besides: url, suffix: "", format: result.format)
        return FileJobResult(
            source: url, outcome: .converted(output: output), originalBytes: original.count,
            newBytes: result.newSize)
    }

    /// Longest side in pixels, read from the file header without decoding the pixels.
    static func longestSide(of data: Data) -> Int? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = props[kCGImagePropertyPixelWidth] as? Int,
            let height = props[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return max(width, height)
    }

    private static func temporarySibling(of url: URL) -> URL {
        url.deletingLastPathComponent().appendingPathComponent(".optimos-\(UUID().uuidString).tmp")
    }

    /// Writes next to the target and swaps it in, so a crash never leaves a half-written image.
    private static func replace(_ url: URL, with bytes: Data) throws {
        let temp = temporarySibling(of: url)
        try bytes.write(to: temp)
        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw error
        }
    }

    /// `photo.png` → `photo.webp`, or `photo 2.webp` if that exists. The final rename fails instead of
    /// overwriting, so two jobs racing for one name can never clobber each other.
    private static func writeNew(
        _ bytes: Data, besides url: URL, suffix: String, format: ImageFormat
    ) throws -> URL {
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent + suffix
        let temp = temporarySibling(of: url)
        try bytes.write(to: temp)
        var counter = 1
        while true {
            let name = counter == 1 ? "\(base).\(format.fileExtension)" : "\(base) \(counter).\(format.fileExtension)"
            let destination = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: destination.path) {
                counter += 1
                continue
            }
            do {
                try FileManager.default.moveItem(at: temp, to: destination)
                return destination
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                counter += 1
            } catch {
                try? FileManager.default.removeItem(at: temp)
                throw error
            }
        }
    }
}
