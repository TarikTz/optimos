import CoreGraphics
import Foundation
import ImageIO

public struct RGBColor: Sendable, Equatable, Codable {
    public var r: UInt8, g: UInt8, b: UInt8
    public init(r: UInt8, g: UInt8, b: UInt8) { self.r = r; self.g = g; self.b = b }
    public static let white = RGBColor(r: 255, g: 255, b: 255)

    /// "#RRGGBB" or "RRGGBB".
    public init?(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(r: UInt8(v >> 16 & 0xFF), g: UInt8(v >> 8 & 0xFF), b: UInt8(v & 0xFF))
    }
}

public struct EncodeOptions: Sendable, Equatable {
    /// 1...100. nil means "format default" (lossless for same-format optimize).
    public var quality: Int?
    /// WebP only: force lossless encoding.
    public var lossless: Bool
    /// PNG only: opt-in pngquant-style quantization range, e.g. 60...90.
    public var quantizeQuality: ClosedRange<Int>?
    /// Used to flatten transparency when writing JPEG.
    public var background: RGBColor?

    public init(
        quality: Int? = nil, lossless: Bool = false,
        quantizeQuality: ClosedRange<Int>? = nil, background: RGBColor? = nil
    ) {
        self.quality = quality
        self.lossless = lossless
        self.quantizeQuality = quantizeQuality
        self.background = background
    }
}

/// A decoded image plus the original bytes while its pixels are untouched.
public struct ImageData: @unchecked Sendable {
    public var cgImage: CGImage
    public var format: ImageFormat
    public var hasTransparency: Bool
    /// EXIF orientation 1...8. `cgImage` is stored un-rotated while this is not 1.
    public var orientation: Int
    /// WebP only: the input used lossless encoding.
    public var isLossless: Bool
    /// Original encoded bytes. nil once pixels have been modified.
    public var source: Data?
    public var stripMetadata = false
    public var optimize = false
    public var pixelsModified = false

    public var width: Int { cgImage.width }
    public var height: Int { cgImage.height }

    public init(
        cgImage: CGImage, format: ImageFormat, hasTransparency: Bool,
        orientation: Int, isLossless: Bool, source: Data?
    ) {
        self.cgImage = cgImage
        self.format = format
        self.hasTransparency = hasTransparency
        self.orientation = orientation
        self.isLossless = isLossless
        self.source = source
    }

    /// Bakes EXIF orientation into the pixels. No-op when already upright.
    public func uprighted() throws -> ImageData {
        guard orientation != 1, let source else { return self }
        guard let src = CGImageSourceCreateWithData(source as CFData, nil) else {
            throw OptimosError.decodeFailed("could not reopen source for rotation")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(cgImage.width, cgImage.height),
        ]
        guard let rotated = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else {
            throw OptimosError.decodeFailed("could not apply EXIF orientation")
        }
        var copy = self
        copy.cgImage = rotated
        copy.orientation = 1
        copy.source = nil
        return copy
    }
}
