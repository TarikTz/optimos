import CoreGraphics
import Foundation

enum Pixels {
    static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// The image's own colour space when it is RGB, otherwise sRGB.
    static func workingSpace(for image: CGImage) -> CGColorSpace {
        if let space = image.colorSpace, space.model == .rgb { return space }
        return sRGB
    }

    /// 8-bit bitmap context. Falls back to sRGB if `space` cannot back a bitmap.
    static func context(
        width: Int, height: Int, space: CGColorSpace, alpha: CGImageAlphaInfo
    ) throws -> CGContext {
        for candidate in [space, sRGB] {
            if let ctx = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: candidate, bitmapInfo: alpha.rawValue)
            {
                ctx.interpolationQuality = .high
                return ctx
            }
        }
        throw OptimosError.encodeFailed("could not create \(width)x\(height) bitmap context")
    }

    private static func pack(_ ctx: CGContext) -> [UInt8] {
        let w = ctx.width, h = ctx.height, stride = ctx.bytesPerRow
        var out = [UInt8](repeating: 0, count: w * h * 4)
        guard let base = ctx.data else { return out }
        out.withUnsafeMutableBytes { dst in
            for y in 0..<h {
                memcpy(dst.baseAddress! + y * w * 4, base + y * stride, w * 4)
            }
        }
        return out
    }

    /// Tightly packed premultiplied RGBA, converted to sRGB.
    static func premultipliedRGBA(_ image: CGImage) throws -> [UInt8] {
        let ctx = try context(width: image.width, height: image.height, space: sRGB, alpha: .premultipliedLast)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pack(ctx)
    }

    /// Tightly packed straight (non-premultiplied) RGBA in sRGB, as libwebp expects.
    static func straightRGBA(_ image: CGImage) throws -> [UInt8] {
        var px = try premultipliedRGBA(image)
        var i = 0
        while i < px.count {
            let a = Int(px[i + 3])
            if a != 0 && a != 255 {
                for c in 0..<3 { px[i + c] = UInt8(min(255, (Int(px[i + c]) * 255 + a / 2) / a)) }
            }
            i += 4
        }
        return px
    }

    static func image(straightRGBA px: [UInt8], width: Int, height: Int) throws -> CGImage {
        guard let provider = CGDataProvider(data: Data(px) as CFData),
            let image = CGImage(
                width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: width * 4, space: sRGB,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { throw OptimosError.decodeFailed("could not build image from RGBA bytes") }
        return image
    }

    /// True only if some pixel is not fully opaque (an unused alpha channel does not count).
    static func hasTransparency(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: break
        }
        // Draw into an alpha-only bitmap: one byte per pixel instead of a full RGBA copy.
        guard let ctx = CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
            let base = ctx.data?.assumingMemoryBound(to: UInt8.self)
        else { return false }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        for y in 0..<image.height {
            let row = base + y * ctx.bytesPerRow
            for x in 0..<image.width where row[x] != 255 { return true }
        }
        return false
    }

    static func resized(_ image: CGImage, to size: (width: Int, height: Int), transparent: Bool) throws -> CGImage {
        let ctx = try context(
            width: size.width, height: size.height, space: workingSpace(for: image),
            alpha: transparent ? .premultipliedLast : .noneSkipLast)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        guard let out = ctx.makeImage() else { throw OptimosError.encodeFailed("resize produced no image") }
        return out
    }

    /// Composites onto an opaque background, producing an image with no alpha.
    static func flattened(_ image: CGImage, onto background: RGBColor) throws -> CGImage {
        let ctx = try context(
            width: image.width, height: image.height, space: workingSpace(for: image), alpha: .noneSkipLast)
        ctx.setFillColor(CGColor(
            srgbRed: CGFloat(background.r) / 255, green: CGFloat(background.g) / 255,
            blue: CGFloat(background.b) / 255, alpha: 1))
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        ctx.fill(rect)
        ctx.draw(image, in: rect)
        guard let out = ctx.makeImage() else { throw OptimosError.encodeFailed("flatten produced no image") }
        return out
    }
}
