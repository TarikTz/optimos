import Foundation

struct PNGCodec: Codec {
    let format = ImageFormat.png

    func decode(_ data: Data) throws -> ImageData {
        try ImageIOSupport.decode(data, as: .png)
    }

    func encode(_ image: ImageData, options: EncodeOptions) throws -> Data {
        var data: Data
        if image.format == .png, let source = image.source {
            data = source
        } else {
            data = try ImageIOSupport.encode(try image.uprighted().cgImage, as: .png)
        }
        if let range = options.quantizeQuality, let quantized = try Self.quantize(data, quality: range) {
            data = quantized
        }
        if image.optimize || image.stripMetadata {
            data = try Self.oxipng(data, strip: image.stripMetadata)
        }
        return data
    }

    /// Lossless. `--strip safe` drops non-essential chunks but keeps colour-profile chunks.
    static func oxipng(_ data: Data, strip: Bool) throws -> Data {
        var args = ["-", "--stdout", "-o", "2"]
        if strip { args += ["--strip", "safe"] }
        let result = try ExternalTool(name: "oxipng").run(args, input: data)
        guard result.status == 0, !result.output.isEmpty else {
            throw OptimosError.encodeFailed("oxipng failed: \(result.errorOutput)")
        }
        return result.output
    }

    /// Lossy palette quantization. nil when pngquant cannot reach the quality (99)
    /// or would not make the file smaller (98).
    static func quantize(_ data: Data, quality: ClosedRange<Int>) throws -> Data? {
        let args = ["--quality=\(quality.lowerBound)-\(quality.upperBound)", "--speed", "3", "-"]
        let result = try ExternalTool(name: "pngquant").run(args, input: data)
        switch result.status {
        case 0 where !result.output.isEmpty: return result.output
        case 98, 99: return nil
        default: throw OptimosError.encodeFailed("pngquant failed: \(result.errorOutput)")
        }
    }
}
