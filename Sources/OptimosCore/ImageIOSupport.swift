import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageIOSupport {
    static func decode(_ data: Data, as format: ImageFormat) throws -> ImageData {
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
