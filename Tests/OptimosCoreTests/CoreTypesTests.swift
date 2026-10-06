import CoreGraphics
import Foundation
import Testing
@testable import OptimosCore

@Suite struct CoreTypesTests {
    @Test func sniffsFormatsFromMagicBytes() {
        #expect(ImageFormat.sniff(Fixtures.png()) == .png)
        #expect(ImageFormat.sniff(Fixtures.jpeg()) == .jpeg)
        #expect(ImageFormat.sniff(Data("RIFF\0\0\0\0WEBPVP8 ".utf8)) == .webp)
        #expect(ImageFormat.sniff(Data([1, 2, 3])) == nil)
    }

    @Test func detectsRealTransparencyNotJustAnAlphaChannel() {
        #expect(!Pixels.hasTransparency(Fixtures.cgImage(transparent: false)))
        #expect(Pixels.hasTransparency(Fixtures.cgImage(transparent: true)))
    }

    @Test func straightRGBARoundTripsOpaquePixels() throws {
        let image = Fixtures.cgImage()
        let straight = try Pixels.straightRGBA(image)
        let rebuilt = try Pixels.image(straightRGBA: straight, width: image.width, height: image.height)
        #expect(try Pixels.premultipliedRGBA(rebuilt) == Pixels.premultipliedRGBA(image))
    }

    @Test func parsesHexColors() {
        #expect(RGBColor(hex: "#FF8000") == RGBColor(r: 255, g: 128, b: 0))
        #expect(RGBColor(hex: "ffffff") == .white)
        #expect(RGBColor(hex: "nope") == nil)
    }
}
