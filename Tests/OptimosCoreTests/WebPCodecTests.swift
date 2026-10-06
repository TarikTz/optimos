import Foundation
import Testing
@testable import OptimosCore

@Suite struct WebPCodecTests {
    @Test func losslessRoundTripKeepsPixels() throws {
        let original = Fixtures.cgImage()
        let webp = Fixtures.webp(lossless: true)
        let decoded = try WebPCodec().decode(webp)
        #expect(decoded.isLossless)
        #expect(try Pixels.premultipliedRGBA(decoded.cgImage) == Pixels.premultipliedRGBA(original))
    }

    @Test func losslessInputStaysLosslessWhenOptimized() throws {
        let input = Fixtures.webp(lossless: true)
        var image = try WebPCodec().decode(input)
        image.optimize = true
        let out = try WebPCodec().encode(image, options: EncodeOptions())
        #expect(try Fixtures.pixels(out) == Fixtures.pixels(input))
    }

    @Test func lossyInputIsLeftAlone() throws {
        let input = Fixtures.webp(lossless: false)
        var image = try WebPCodec().decode(input)
        #expect(!image.isLossless)
        image.optimize = true
        #expect(try WebPCodec().encode(image, options: EncodeOptions()) == input)
    }

    // Invariant: alpha survives where the format supports it.
    @Test func convertsTransparentPngToWebpKeepingAlpha() throws {
        var png = try PNGCodec().decode(Fixtures.png(transparent: true))
        png.optimize = true
        let out = try WebPCodec().encode(png, options: EncodeOptions(quality: 82))
        #expect(ImageFormat.sniff(out) == .webp)
        #expect(try WebPCodec().decode(out).hasTransparency)
    }

    @Test func garbageThrowsDecodeFailed() {
        #expect(throws: OptimosError.self) {
            try WebPCodec().decode(Data("RIFF\0\0\0\0WEBPjunk".utf8))
        }
    }
}
