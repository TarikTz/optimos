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

    // Final review 3: lossless optimize must not quantize RGB where 0 < alpha < 255.
    @Test func losslessOptimizeKeepsSemiTransparentPixelsExactly() throws {
        let input = Fixtures.semiTransparentLosslessWebP()
        let before = try Fixtures.straightPixels(input)
        #expect(Set(stride(from: 3, to: before.count, by: 4).map { before[$0] }) == [30, 90, 200, 255])
        var image = try WebPCodec().decode(input)
        image.optimize = true
        image.stripMetadata = true
        let out = try WebPCodec().encode(image, options: EncodeOptions())
        let after = try Fixtures.straightPixels(out)
        #expect(after.count == before.count)
        var mismatches = 0
        for i in stride(from: 0, to: before.count, by: 4) {
            if after[i + 3] != before[i + 3] { mismatches += 1; continue }
            if before[i + 3] > 0, after[i..<i + 3] != before[i..<i + 3] { mismatches += 1 }
        }
        #expect(mismatches == 0)
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
