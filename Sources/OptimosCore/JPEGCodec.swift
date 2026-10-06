import CoreGraphics
import Foundation
import ImageIO

struct JPEGCodec: Codec {
    let format = ImageFormat.jpeg

    func decode(_ data: Data) throws -> ImageData {
        try ImageIOSupport.decode(data, as: .jpeg)
    }

    func encode(_ image: ImageData, options: EncodeOptions) throws -> Data {
        var data: Data
        var orientation = image.orientation
        if image.format == .jpeg, let source = image.source, options.quality == nil {
            // Pristine and no lossy request: stay on the original bytes (lossless path).
            data = source
        } else {
            let upright = try image.uprighted()
            orientation = 1
            guard let background = upright.hasTransparency ? options.background : RGBColor.white else {
                throw OptimosError.alphaNotSupported(.jpeg)
            }
            let flat = try Pixels.flattened(upright.cgImage, onto: background)
            data = try ImageIOSupport.encode(
                flat, as: .jpeg,
                properties: [kCGImageDestinationLossyCompressionQuality: Double(options.quality ?? 85) / 100])
        }
        if image.optimize || image.stripMetadata {
            // A rotated photo needs its EXIF orientation, so keep everything in that case.
            let keepAll = orientation != 1 || !image.stripMetadata
            data = try Self.jpegtran(data, copy: keepAll ? "all" : "icc")
        }
        return data
    }

    /// Lossless Huffman optimisation + progressive scan. `copy` is "all" or "icc".
    static func jpegtran(_ data: Data, copy: String) throws -> Data {
        let result = try ExternalTool(name: "jpegtran")
            .run(["-copy", copy, "-optimize", "-progressive"], input: data)
        guard result.status == 0, !result.output.isEmpty else {
            throw OptimosError.encodeFailed("jpegtran failed: \(result.errorOutput)")
        }
        return result.output
    }
}
