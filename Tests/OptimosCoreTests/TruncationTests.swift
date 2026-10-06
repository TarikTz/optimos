import Foundation
import Testing
@testable import OptimosCore

// Final review 4: ImageIO happily decodes truncated PNG/JPEG files, so we must reject them.
@Suite struct TruncationTests {
    static let truncatedPNGError = OptimosError.decodeFailed("truncated PNG")
    static let truncatedJPEGError = OptimosError.decodeFailed("truncated JPEG")

    /// A valid PNG minus its last 20 bytes (IEND and the tail of the last IDAT).
    static func truncatedPNG() -> Data {
        let png = Fixtures.png(width: 200, height: 150)
        return png.prefix(png.count - 20)
    }

    /// A valid JPEG cut in the middle of its scan data.
    static func truncatedJPEG() throws -> Data {
        let jpeg = Fixtures.jpeg(width: 200, height: 150)
        let bytes = [UInt8](jpeg)
        let sos = try #require((0..<bytes.count - 1).first { bytes[$0] == 0xFF && bytes[$0 + 1] == 0xDA })
        return jpeg.prefix(sos + (bytes.count - sos) / 2)
    }

    @Test func codecsRejectTruncatedFiles() throws {
        #expect(throws: Self.truncatedPNGError) { try PNGCodec().decode(Self.truncatedPNG()) }
        let jpeg = try Self.truncatedJPEG()
        #expect(throws: Self.truncatedJPEGError) { try JPEGCodec().decode(jpeg) }
    }

    @Test func pipelinesRejectTruncatedFiles() async throws {
        let toWebP = try Preset(name: "convert", format: .webp, quality: 80).pipeline()
        let toPNG = try Preset(name: "convert", format: .png).pipeline()
        let png = Self.truncatedPNG(), jpeg = try Self.truncatedJPEG()
        for pipeline in [Pipeline.defaultOptimize, toWebP, toPNG] {
            await #expect(throws: Self.truncatedPNGError) { try await pipeline.run(png) }
            await #expect(throws: Self.truncatedJPEGError) { try await pipeline.run(jpeg) }
        }
    }

    @Test func validFilesStillDecode() throws {
        let progressive = try JPEGCodec.jpegtran(Fixtures.jpeg(width: 200, height: 150), copy: "all")
        #expect(try JPEGCodec().decode(progressive).width == 200)
        #expect(try JPEGCodec().decode(Fixtures.jpeg(orientation: 6, gps: true)).orientation == 6)
        #expect(try PNGCodec().decode(Fixtures.png(width: 200, height: 150, transparent: true)).width == 200)
        // Trailing bytes after EOI are allowed.
        #expect(try JPEGCodec().decode(Fixtures.jpeg() + Data([0, 1, 2, 3])).width == 64)
    }
}
