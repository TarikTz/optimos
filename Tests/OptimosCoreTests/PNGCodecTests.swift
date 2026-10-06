import CoreGraphics
import Foundation
import Testing
@testable import OptimosCore

@Suite struct PNGCodecTests {
    @Test func decodesSizeAndTransparency() throws {
        let opaque = try PNGCodec().decode(Fixtures.png())
        #expect(opaque.width == 64 && opaque.height == 48)
        #expect(!opaque.hasTransparency)
        #expect(try PNGCodec().decode(Fixtures.png(transparent: true)).hasTransparency)
    }

    // Invariants: pixels identical under lossless optimize, alpha survives.
    @Test func losslessOptimizeKeepsPixelsAndAlpha() throws {
        let input = Fixtures.png(transparent: true)
        var image = try PNGCodec().decode(input)
        image.optimize = true
        image.stripMetadata = true
        let out = try PNGCodec().encode(image, options: EncodeOptions())
        #expect(try Fixtures.pixels(out) == Fixtures.pixels(input))
        #expect(try PNGCodec().decode(out).hasTransparency)
    }

    // Review Focus 1: macOS screenshots are Display P3.
    @Test func optimizeKeepsDisplayP3Profile() throws {
        let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
        var image = try PNGCodec().decode(Fixtures.png(space: p3))
        image.optimize = true
        image.stripMetadata = true
        let out = try PNGCodec().encode(image, options: EncodeOptions())
        let name = try PNGCodec().decode(out).cgImage.colorSpace?.name as String?
        #expect(name == (CGColorSpace.displayP3 as String))
    }

    @Test func quantizeShrinksOrDeclines() throws {
        let input = Fixtures.png()
        let result = try PNGCodec.quantize(input, quality: 40...90)
        #expect(result == nil || result!.count < input.count)
    }

    @Test func encodesFromPixelsWhenSourceIsGone() throws {
        var image = Fixtures.imageData(Fixtures.cgImage())
        image.format = .jpeg  // pretend it came from elsewhere
        let out = try PNGCodec().encode(image, options: EncodeOptions())
        #expect(ImageFormat.sniff(out) == .png)
    }
}
