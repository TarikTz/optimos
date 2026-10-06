import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageIOSupport {
    static func decode(_ data: Data, as format: ImageFormat) throws -> ImageData {
        try checkComplete(data, as: format)
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceGetCount(src) > 0,
            let image = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else { throw OptimosError.decodeFailed("ImageIO could not read \(format.rawValue) data") }
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        let raw = (props?[kCGImagePropertyOrientation] as? Int) ?? 1
        return ImageData(
            cgImage: image, format: format, hasTransparency: Pixels.hasTransparency(image),
            orientation: (1...8).contains(raw) ? raw : 1, isLossless: false, source: data)
    }

    /// ImageIO decodes truncated files without complaint, so check the structure first.
    /// Deliberately conservative: only the end of the file is examined.
    static func checkComplete(_ data: Data, as format: ImageFormat) throws {
        let bytes = [UInt8](data)
        switch format {
        case .png:
            // Last chunk must be a complete IEND: length 0, "IEND", 4-byte CRC, nothing after.
            let iend: [UInt8] = [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44]
            guard bytes.count >= 8 + 12, Array(bytes[(bytes.count - 12)..<(bytes.count - 4)]) == iend else {
                throw OptimosError.decodeFailed("truncated PNG")
            }
        case .jpeg:
            // An EOI (FF D9) must follow the last start-of-scan (FF DA). Trailing bytes after EOI are fine.
            guard let sos = lastMarker(0xDA, in: bytes),
                bytes.indices.dropFirst(sos + 2).dropLast().contains(where: { bytes[$0] == 0xFF && bytes[$0 + 1] == 0xD9 })
            else { throw OptimosError.decodeFailed("truncated JPEG") }
        case .webp:
            break
        }
    }

    private static func lastMarker(_ marker: UInt8, in bytes: [UInt8]) -> Int? {
        guard bytes.count >= 2 else { return nil }
        return stride(from: bytes.count - 2, through: 0, by: -1).first {
            bytes[$0] == 0xFF && bytes[$0 + 1] == marker
        }
    }

    static func encode(_ image: CGImage, as format: ImageFormat, properties: [CFString: Any] = [:]) throws -> Data {
        let type: UTType
        switch format {
        case .png: type = .png
        case .jpeg: type = .jpeg
        case .webp: throw OptimosError.encodeFailed("ImageIO does not encode WebP")
        }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, type.identifier as CFString, 1, nil) else {
            throw OptimosError.encodeFailed("could not create \(format.rawValue) destination")
        }
        CGImageDestinationAddImage(dest, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw OptimosError.encodeFailed("ImageIO failed to write \(format.rawValue)")
        }
        return out as Data
    }
}
