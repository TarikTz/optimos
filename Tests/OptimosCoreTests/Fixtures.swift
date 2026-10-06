import CoreGraphics
import Foundation
import ImageIO
@testable import OptimosCore

enum Fixtures {
    /// A gradient with some noise so compressors have something to chew on.
    /// With `transparent`, the left half has alpha 90.
    static func cgImage(
        width: Int = 64, height: Int = 48, transparent: Bool = false,
        space: CGColorSpace = Pixels.sRGB
    ) -> CGImage {
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let base = ctx.data!.assumingMemoryBound(to: UInt8.self)
        for y in 0..<height {
            for x in 0..<width {
                let a = transparent && x < width / 2 ? 90 : 255
                let o = y * ctx.bytesPerRow + x * 4
                base[o] = UInt8(x * 255 / max(width - 1, 1) * a / 255)
                base[o + 1] = UInt8(y * 255 / max(height - 1, 1) * a / 255)
                base[o + 2] = UInt8((x * y) % 256 * a / 255)
                base[o + 3] = UInt8(a)
            }
        }
        return ctx.makeImage()!
    }

    /// PNG written with an alpha channel even when `transparent` is false.
    static func png(
        width: Int = 64, height: Int = 48, transparent: Bool = false,
        space: CGColorSpace = Pixels.sRGB
    ) -> Data {
        try! ImageIOSupport.encode(
            cgImage(width: width, height: height, transparent: transparent, space: space), as: .png)
    }

    static func jpeg(
        width: Int = 64, height: Int = 48, orientation: Int = 1, quality: Double = 0.9
    ) -> Data {
        let flat = try! Pixels.flattened(cgImage(width: width, height: height), onto: .white)
        return try! ImageIOSupport.encode(
            flat, as: .jpeg,
            properties: [
                kCGImagePropertyOrientation: orientation,
                kCGImageDestinationLossyCompressionQuality: quality,
            ])
    }

    static func imageData(_ image: CGImage) -> ImageData {
        ImageData(
            cgImage: image, format: .png, hasTransparency: Pixels.hasTransparency(image),
            orientation: 1, isLossless: false, source: nil)
    }

    static func webp(lossless: Bool, quality: Int = 80) -> Data {
        try! WebPCodec().encode(
            imageData(cgImage()), options: EncodeOptions(quality: lossless ? nil : quality, lossless: lossless))
    }

    /// Premultiplied sRGB pixels of any supported image, for equality checks.
    static func pixels(_ data: Data) throws -> [UInt8] {
        if ImageFormat.sniff(data) == .webp {
            return try Pixels.premultipliedRGBA(WebPCodec().decode(data).cgImage)
        }
        let src = CGImageSourceCreateWithData(data as CFData, nil)!
        return try Pixels.premultipliedRGBA(CGImageSourceCreateImageAtIndex(src, 0, nil)!)
    }
}
