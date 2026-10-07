import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Formats OptimosCore can read (through macOS ImageIO) but not optimize in place or write:
/// HEIC/HEIF, TIFF and BMP. They are converted: decoded upright into a lossless PNG that then goes
/// through the normal pipeline to PNG, JPEG or WebP.
enum ConvertibleInput {
    struct Decoded {
        let png: Data
        /// The output format when the user chose "keep format": photos become JPEG, the rest PNG.
        let defaultTarget: ImageFormat
    }

    static let fileExtensions: Set<String> = ["heic", "heif", "tif", "tiff", "bmp"]

    /// nil if `data` is not one of these formats (or cannot be decoded).
    static func decode(_ data: Data) throws -> Decoded? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let identifier = CGImageSourceGetType(source) as String?,
            let type = UTType(identifier),
            CGImageSourceGetCount(source) > 0
        else { return nil }
        let target: ImageFormat
        if type.conforms(to: .heic) || type.conforms(to: .heif) {
            target = .jpeg
        } else if type.conforms(to: .tiff) || type.conforms(to: .bmp) {
            target = .png
        } else {
            return nil
        }
        guard let first = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OptimosError.decodeFailed("could not read the image")
        }
        // Bake the orientation into the pixels (photos from a phone are often stored rotated).
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(first.width, first.height),
        ]
        let upright = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) ?? first
        return Decoded(png: try ImageIOSupport.encode(upright, as: .png), defaultTarget: target)
    }
}
