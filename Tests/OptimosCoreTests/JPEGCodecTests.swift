import Foundation
import Testing
@testable import OptimosCore

@Suite struct JPEGCodecTests {
    // Invariant: pixels identical under lossless optimize.
    @Test func losslessOptimizeKeepsPixels() throws {
        let input = Fixtures.jpeg()
        var image = try JPEGCodec().decode(input)
        image.optimize = true
        image.stripMetadata = true
        let out = try JPEGCodec().encode(image, options: EncodeOptions())
        #expect(try Fixtures.pixels(out) == Fixtures.pixels(input))
    }

    // Review Focus 3: optimize must not un-rotate a rotated photo.
    @Test func optimizeKeepsExifOrientation() throws {
        var image = try JPEGCodec().decode(Fixtures.jpeg(orientation: 6))
        #expect(image.orientation == 6)
        image.optimize = true
        image.stripMetadata = true
        let out = try JPEGCodec().encode(image, options: EncodeOptions())
        #expect(try JPEGCodec().decode(out).orientation == 6)
    }

    // Final review 1b: a rotated photo keeps its orientation but loses GPS, losslessly.
    @Test func optimizeOfRotatedPhotoDropsGPSKeepsOrientationAndPixels() throws {
        let input = Fixtures.jpeg(orientation: 6, gps: true)
        #expect(Fixtures.hasGPS(input))
        var image = try JPEGCodec().decode(input)
        image.optimize = true
        image.stripMetadata = true
        let out = try JPEGCodec().encode(image, options: EncodeOptions())
        #expect(!Fixtures.hasGPS(out))
        #expect(try JPEGCodec().decode(out).orientation == 6)
        #expect(try Fixtures.pixels(out) == Fixtures.pixels(input))
    }

    // Invariant: alpha is never silently dropped.
    @Test func transparentImageToJpegThrows() throws {
        let image = Fixtures.imageData(Fixtures.cgImage(transparent: true))
        #expect(throws: OptimosError.alphaNotSupported(.jpeg)) {
            try JPEGCodec().encode(image, options: EncodeOptions())
        }
    }

    @Test func transparentImageToJpegWorksWithBackground() throws {
        let image = Fixtures.imageData(Fixtures.cgImage(transparent: true))
        let out = try JPEGCodec().encode(image, options: EncodeOptions(background: .white))
        #expect(ImageFormat.sniff(out) == .jpeg)
    }

    // Review Focus 2: an alpha channel that is all 255 is not transparency.
    @Test func opaquePngWithAlphaChannelConvertsToJpeg() throws {
        let png = try PNGCodec().decode(Fixtures.png())
        let out = try JPEGCodec().encode(png, options: EncodeOptions(quality: 80))
        let decoded = try JPEGCodec().decode(out)
        #expect(decoded.width == 64 && decoded.height == 48)
    }
}
