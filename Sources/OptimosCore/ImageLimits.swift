import Foundation
import ImageIO

/// A small file can declare enormous dimensions (a "decompression bomb") and make the decoder allocate
/// gigabytes. The size is read from the header and checked before any pixels are decoded.
enum ImageLimits {
    static let maxPixels = 100_000_000
    static let maxSide = 30_000

    static func check(width: Int, height: Int) throws {
        guard width > 0, height > 0 else { return }
        let (pixels, overflow) = width.multipliedReportingOverflow(by: height)
        if width > maxSide || height > maxSide || overflow || pixels > maxPixels {
            throw OptimosError.imageTooLarge(width: width, height: height)
        }
    }

    /// Reads the declared size from the header (ImageIO needs no pixel decode for this) and checks it.
    /// Data ImageIO cannot read is left for the decoder to reject.
    static func check(_ data: Data) throws {
        // PNG: the size is at a fixed place in the IHDR chunk, so read it directly instead of
        // trusting a decoder to report it for damaged or hostile files.
        if data.count >= 24, ImageFormat.sniff(data) == .png {
            let b = [UInt8](data[16..<24])
            let width = Int(b[0]) << 24 | Int(b[1]) << 16 | Int(b[2]) << 8 | Int(b[3])
            let height = Int(b[4]) << 24 | Int(b[5]) << 16 | Int(b[6]) << 8 | Int(b[7])
            try check(width: width, height: height)
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = props[kCGImagePropertyPixelWidth] as? Int,
            let height = props[kCGImagePropertyPixelHeight] as? Int
        else { return }
        try check(width: width, height: height)
    }
}
