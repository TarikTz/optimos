import Foundation

public struct Preset: Codable, Sendable, Equatable {
    public var name: String
    /// nil keeps the input format.
    public var format: ImageFormat?
    public var quality: Int?
    /// WebP output: use lossless encoding.
    public var lossless: Bool
    public var maxWidth: Int?
    public var maxHeight: Int?
    public var stripMetadata: Bool
    public var optimize: Bool
    /// PNG output: opt-in lossy quantization range.
    public var quantizeQuality: ClosedRange<Int>?
    /// "#RRGGBB" used to flatten transparency when writing JPEG.
    public var backgroundHex: String?

    public init(
        name: String, format: ImageFormat? = nil, quality: Int? = nil, lossless: Bool = false,
        maxWidth: Int? = nil, maxHeight: Int? = nil, stripMetadata: Bool = true, optimize: Bool = true,
        quantizeQuality: ClosedRange<Int>? = nil, backgroundHex: String? = nil
    ) {
        self.name = name
        self.format = format
        self.quality = quality
        self.lossless = lossless
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.stripMetadata = stripMetadata
        self.optimize = optimize
        self.quantizeQuality = quantizeQuality
        self.backgroundHex = backgroundHex
    }

    /// Fixed order: resize, strip metadata, optimize, then encode (see spec §4).
    public func pipeline() throws -> Pipeline {
        var background: RGBColor?
        if let hex = backgroundHex {
            guard let color = RGBColor(hex: hex) else {
                throw OptimosError.invalidOptions("background '\(hex)' is not a #RRGGBB colour")
            }
            background = color
        }
        var operations: [any Operation] = []
        if maxWidth != nil || maxHeight != nil {
            operations.append(Resize(.fit(maxWidth: maxWidth, maxHeight: maxHeight)))
        }
        if stripMetadata { operations.append(StripMetadata()) }
        if optimize { operations.append(Optimize()) }
        return Pipeline(
            operations: operations,
            output: OutputSpec(
                format: format,
                options: EncodeOptions(
                    quality: quality, lossless: lossless,
                    quantizeQuality: quantizeQuality, background: background)))
    }

    public static let builtIns: [Preset] = [
        Preset(name: "Website", format: .webp, quality: 82, maxWidth: 1600),
        Preset(name: "Screenshot", format: .png),
        Preset(name: "GitHub", format: .webp, quality: 85, maxWidth: 2000),
        Preset(name: "Slack", format: .jpeg, quality: 80, maxWidth: 1600),
    ]
}
