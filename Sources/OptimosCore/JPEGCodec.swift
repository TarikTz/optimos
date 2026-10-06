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
        if image.stripMetadata {
            data = try Self.losslessStrip(data, orientation: orientation)
        } else if image.optimize {
            data = try Self.jpegtran(data, copy: "all")
        }
        return data
    }

    /// Lossless optimise + strip, keeping the colour profile. A rotated photo (orientation != 1)
    /// also keeps its EXIF orientation; everything else (GPS, XMP, other EXIF) is dropped.
    static func losslessStrip(_ data: Data, orientation: Int) throws -> Data {
        if orientation == 1 { return try jpegtran(data, copy: "icc") }
        return try removingMetadata(keepingOrientation: orientation, try jpegtran(data, copy: "all"))
    }

    /// Rewrites the metadata without touching the compressed scan data
    /// (`CGImageDestinationCopyImageSource` is ImageIO's lossless metadata-editing path).
    static func removingMetadata(keepingOrientation orientation: Int, _ data: Data) throws -> Data {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil), let type = CGImageSourceGetType(src)
        else { throw OptimosError.encodeFailed("could not reopen JPEG to strip metadata") }
        let metadata = CGImageMetadataCreateMutable()
        guard CGImageMetadataSetValueWithPath(
            metadata, nil, "tiff:Orientation" as CFString, "\(orientation)" as CFString)
        else { throw OptimosError.encodeFailed("could not set EXIF orientation") }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, type, 1, nil) else {
            throw OptimosError.encodeFailed("could not create JPEG destination to strip metadata")
        }
        let options: [CFString: Any] = [
            kCGImageDestinationMetadata: metadata,  // replaces all EXIF/TIFF with just the orientation
            kCGImageMetadataShouldExcludeGPS: true,
            kCGImageMetadataShouldExcludeXMP: true,
        ]
        var error: Unmanaged<CFError>?
        guard CGImageDestinationCopyImageSource(dest, src, options as CFDictionary, &error) else {
            let why = error.map { "\($0.takeRetainedValue())" } ?? "unknown error"
            throw OptimosError.encodeFailed("could not strip JPEG metadata: \(why)")
        }
        return out as Data
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
