import CWebP
import Foundation

struct WebPCodec: Codec {
    let format = ImageFormat.webp

    func decode(_ data: Data) throws -> ImageData {
        var features = WebPBitstreamFeatures()
        let status = data.withUnsafeBytes {
            WebPGetFeatures($0.bindMemory(to: UInt8.self).baseAddress, data.count, &features)
        }
        guard status == VP8_STATUS_OK else {
            throw OptimosError.decodeFailed("libwebp rejected the data (status \(status.rawValue))")
        }
        if features.has_animation != 0 { throw OptimosError.unsupportedFormat }
        try ImageLimits.check(width: Int(features.width), height: Int(features.height))

        let decoded = try Self.straightRGBA(data)
        let image = try Pixels.image(straightRGBA: decoded.pixels, width: decoded.width, height: decoded.height)
        return ImageData(
            cgImage: image, format: .webp, hasTransparency: Pixels.hasTransparency(image),
            orientation: 1, isLossless: features.format == 2, source: data)
    }

    func encode(_ image: ImageData, options: EncodeOptions) throws -> Data {
        let sameFormat = image.format == .webp
        if sameFormat, let source = image.source, !image.isLossless,
            options.quality == nil, !options.lossless
        {
            return source  // recompressing lossy WebP only degrades it
        }
        let lossless = options.lossless || (sameFormat && image.isLossless && options.quality == nil)
        if lossless, sameFormat, let source = image.source, !image.pixelsModified {
            // Pristine WebP: re-encode libwebp's own straight RGBA. Going through CGImage would
            // premultiply to 8 bits and quantize RGB wherever 0 < alpha < 255.
            let decoded = try Self.straightRGBA(source)
            return try Self.encode(
                straightRGBA: decoded.pixels, width: decoded.width, height: decoded.height, lossless: true)
        }

        let upright = try image.uprighted()
        let w = upright.width, h = upright.height
        let rgba = try Pixels.straightRGBA(upright.cgImage)

        return try Self.encode(straightRGBA: rgba, width: w, height: h, lossless: lossless, quality: options.quality)
    }

    /// libwebp's own straight (non-premultiplied) RGBA decode, exact for every alpha value.
    static func straightRGBA(_ data: Data) throws -> (pixels: [UInt8], width: Int, height: Int) {
        var w: Int32 = 0, h: Int32 = 0
        let decoded = data.withUnsafeBytes {
            WebPDecodeRGBA($0.bindMemory(to: UInt8.self).baseAddress, data.count, &w, &h)
        }
        guard let ptr = decoded else { throw OptimosError.decodeFailed("libwebp could not decode pixels") }
        defer { WebPFree(ptr) }
        return (Array(UnsafeBufferPointer(start: ptr, count: Int(w) * Int(h) * 4)), Int(w), Int(h))
    }

    /// Encodes tightly packed straight RGBA. `quality` is ignored when `lossless`.
    static func encode(
        straightRGBA rgba: [UInt8], width w: Int, height h: Int, lossless: Bool, quality: Int? = nil
    ) throws -> Data {
        var out: UnsafeMutablePointer<UInt8>?
        let size: Int = rgba.withUnsafeBufferPointer { buf in
            if lossless {
                return WebPEncodeLosslessRGBA(buf.baseAddress, Int32(w), Int32(h), Int32(w * 4), &out)
            }
            return WebPEncodeRGBA(
                buf.baseAddress, Int32(w), Int32(h), Int32(w * 4), Float(quality ?? 80), &out)
        }
        guard size > 0, let out else { throw OptimosError.encodeFailed("libwebp produced no output") }
        defer { WebPFree(out) }
        return Data(bytes: out, count: size)
    }
}
