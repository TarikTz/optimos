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

        var w: Int32 = 0, h: Int32 = 0
        let decoded = data.withUnsafeBytes {
            WebPDecodeRGBA($0.bindMemory(to: UInt8.self).baseAddress, data.count, &w, &h)
        }
        guard let ptr = decoded else { throw OptimosError.decodeFailed("libwebp could not decode pixels") }
        defer { WebPFree(ptr) }
        let pixels = Array(UnsafeBufferPointer(start: ptr, count: Int(w) * Int(h) * 4))
        let image = try Pixels.image(straightRGBA: pixels, width: Int(w), height: Int(h))
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

        let upright = try image.uprighted()
        let w = upright.width, h = upright.height
        let rgba = try Pixels.straightRGBA(upright.cgImage)

        var out: UnsafeMutablePointer<UInt8>?
        let size: Int = rgba.withUnsafeBufferPointer { buf in
            if lossless {
                return WebPEncodeLosslessRGBA(buf.baseAddress, Int32(w), Int32(h), Int32(w * 4), &out)
            }
            return WebPEncodeRGBA(
                buf.baseAddress, Int32(w), Int32(h), Int32(w * 4), Float(options.quality ?? 80), &out)
        }
        guard size > 0, let out else { throw OptimosError.encodeFailed("libwebp produced no output") }
        defer { WebPFree(out) }
        return Data(bytes: out, count: size)
    }
}
