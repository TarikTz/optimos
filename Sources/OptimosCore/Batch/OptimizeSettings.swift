import Foundation

public enum OptimizeLevel: String, Codable, CaseIterable, Sendable {
    case lossless, balanced, smallest
}

/// What the user chose in the optimizer window. The only place the quality numbers live.
public struct OptimizeSettings: Equatable, Codable, Sendable {
    public var level: OptimizeLevel
    /// nil keeps each file's own format.
    public var format: ImageFormat?
    /// Longest side in pixels; nil keeps the original size. Images are only ever shrunk.
    public var maxSide: Int?
    /// Keep credits, captions and location instead of stripping them (JPEG and PNG; WebP is re-encoded).
    public var keepMetadata: Bool
    /// Same-format files are overwritten (true) or written as `name-optimized.ext` (false).
    public var replaceOriginals: Bool

    public init(
        level: OptimizeLevel = .balanced, format: ImageFormat? = nil, maxSide: Int? = nil,
        keepMetadata: Bool = false, replaceOriginals: Bool = true
    ) {
        self.level = level
        self.format = format
        self.maxSide = maxSide
        self.keepMetadata = keepMetadata
        self.replaceOriginals = replaceOriginals
    }

    private enum CodingKeys: String, CodingKey {
        case level, format, maxSide, keepMetadata, replaceOriginals
    }

    /// Settings stored by older versions lack the newer keys; those take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            level: try c.decodeIfPresent(OptimizeLevel.self, forKey: .level) ?? .balanced,
            format: try c.decodeIfPresent(ImageFormat.self, forKey: .format),
            maxSide: try c.decodeIfPresent(Int.self, forKey: .maxSide),
            keepMetadata: try c.decodeIfPresent(Bool.self, forKey: .keepMetadata) ?? false,
            replaceOriginals: try c.decodeIfPresent(Bool.self, forKey: .replaceOriginals) ?? true)
    }

    /// True if `data` is larger than the max size and will therefore be shrunk.
    func willShrink(_ data: Data) -> Bool {
        maxSide.map { (FileJob.longestSide(of: data) ?? 0) > $0 } ?? false
    }

    /// Runs the settings over image bytes (used for screenshots as well as files).
    public func process(_ data: Data) async throws -> ProcessedImage {
        guard let inputFormat = ImageFormat.sniff(data) else { throw OptimosError.unsupportedFormat }
        return try await pipeline(inputFormat: inputFormat, willShrink: willShrink(data)).run(data)
    }

    /// Encoder options for one output format.
    /// - Parameter reencodes: true when the pixels will be re-encoded anyway (converting or shrinking),
    ///   so even Lossless JPEG output needs an explicit high quality instead of the lossless path.
    func options(for target: ImageFormat, reencodes: Bool) -> EncodeOptions {
        switch (level, target) {
        case (.lossless, .jpeg): EncodeOptions(quality: reencodes ? 95 : nil, background: .white)
        case (.lossless, .webp): EncodeOptions(lossless: true)
        case (.lossless, .png): EncodeOptions()
        case (.balanced, .jpeg): EncodeOptions(quality: 82, background: .white)
        case (.balanced, .webp): EncodeOptions(quality: 80)
        case (.balanced, .png): EncodeOptions(quantizeQuality: 65...85)
        case (.smallest, .jpeg): EncodeOptions(quality: 70, background: .white)
        case (.smallest, .webp): EncodeOptions(quality: 65)
        case (.smallest, .png): EncodeOptions(quantizeQuality: 40...65)
        }
    }

    func pipeline(inputFormat: ImageFormat, willShrink: Bool) -> Pipeline {
        let target = format ?? inputFormat
        var operations: [any Operation] = []
        if willShrink, let maxSide {
            operations.append(Resize(.fit(maxWidth: maxSide, maxHeight: maxSide)))
        }
        if !keepMetadata { operations.append(StripMetadata()) }
        operations.append(Optimize())
        return Pipeline(
            operations: operations,
            output: OutputSpec(
                format: format,
                options: options(for: target, reencodes: willShrink || target != inputFormat)))
    }
}
