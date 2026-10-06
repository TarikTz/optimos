import Foundation

public protocol Operation: Sendable {
    func apply(_ image: ImageData) throws -> ImageData
}

/// Marks the image so the encoder strips non-essential metadata (colour profile is kept).
public struct StripMetadata: Operation {
    public init() {}
    public func apply(_ image: ImageData) throws -> ImageData {
        var copy = image
        copy.stripMetadata = true
        return copy
    }
}

/// Marks the image so the encoder runs its lossless optimizer.
public struct Optimize: Operation {
    public init() {}
    public func apply(_ image: ImageData) throws -> ImageData {
        var copy = image
        copy.optimize = true
        return copy
    }
}

public struct Resize: Operation {
    public enum Mode: Sendable, Equatable {
        case width(Int)
        case height(Int)
        case percent(Double)
        /// Shrinks to fit inside the box, never upscales, keeps aspect ratio.
        case fit(maxWidth: Int?, maxHeight: Int?)
        /// Ignores aspect ratio.
        case exact(width: Int, height: Int)
    }

    public var mode: Mode
    public init(_ mode: Mode) { self.mode = mode }

    func targetSize(width w: Int, height h: Int) throws -> (width: Int, height: Int) {
        func pixels(_ v: Double) -> Int { max(1, Int(v.rounded())) }
        func positive(_ v: Int) throws {
            guard v > 0 else { throw OptimosError.invalidOptions("sizes must be greater than zero") }
        }
        switch mode {
        case .width(let tw):
            try positive(tw)
            return (tw, pixels(Double(h) * Double(tw) / Double(w)))
        case .height(let th):
            try positive(th)
            return (pixels(Double(w) * Double(th) / Double(h)), th)
        case .percent(let p):
            guard p > 0 else { throw OptimosError.invalidOptions("percent must be greater than zero") }
            return (pixels(Double(w) * p / 100), pixels(Double(h) * p / 100))
        case .exact(let tw, let th):
            try positive(tw)
            try positive(th)
            return (tw, th)
        case .fit(let maxW, let maxH):
            var scale = 1.0
            if let maxW { try positive(maxW); scale = min(scale, Double(maxW) / Double(w)) }
            if let maxH { try positive(maxH); scale = min(scale, Double(maxH) / Double(h)) }
            return (pixels(Double(w) * scale), pixels(Double(h) * scale))
        }
    }

    public func apply(_ image: ImageData) throws -> ImageData {
        var upright = try image.uprighted()
        let size = try targetSize(width: upright.width, height: upright.height)
        if size.width == upright.width && size.height == upright.height { return image }
        upright.cgImage = try Pixels.resized(upright.cgImage, to: size, transparent: upright.hasTransparency)
        upright.source = nil
        upright.pixelsModified = true
        return upright
    }
}
