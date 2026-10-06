import Foundation
import Testing
@testable import OptimosCore

@Suite struct PipelineTests {
    // MARK: Resize maths (pure)

    @Test func resizeTargetSizes() throws {
        #expect(try Resize(.width(100)).targetSize(width: 200, height: 100) == (100, 50))
        #expect(try Resize(.height(50)).targetSize(width: 200, height: 100) == (100, 50))
        #expect(try Resize(.percent(50)).targetSize(width: 200, height: 100) == (100, 50))
        #expect(try Resize(.exact(width: 10, height: 20)).targetSize(width: 200, height: 100) == (10, 20))
        #expect(try Resize(.fit(maxWidth: 100, maxHeight: nil)).targetSize(width: 200, height: 100) == (100, 50))
        // fit never upscales
        #expect(try Resize(.fit(maxWidth: 1000, maxHeight: 1000)).targetSize(width: 200, height: 100) == (200, 100))
    }

    // Review Focus 5: never produce a 0-pixel dimension; reject nonsense.
    @Test func resizeNeverReachesZeroAndRejectsNonsense() throws {
        #expect(try Resize(.percent(1)).targetSize(width: 10, height: 10) == (1, 1))
        #expect(try Resize(.fit(maxWidth: 50, maxHeight: nil)).targetSize(width: 1, height: 1) == (1, 1))
        #expect(throws: OptimosError.self) { try Resize(.width(0)).targetSize(width: 10, height: 10) }
        #expect(throws: OptimosError.self) { try Resize(.percent(-5)).targetSize(width: 10, height: 10) }
    }

    // MARK: Invariants

    @Test func defaultOptimizeKeepsPixelsAndNeverGrows() async throws {
        for input in [Fixtures.png(), Fixtures.png(transparent: true), Fixtures.jpeg()] {
            let result = try await Pipeline.defaultOptimize.run(input)
            #expect(result.newSize <= result.originalSize)
            #expect(try Fixtures.pixels(result.bytes) == Fixtures.pixels(input))
        }
    }

    // Review Focus 4
    @Test func optimizingTwiceNeverGrows() async throws {
        let once = try await Pipeline.defaultOptimize.run(Fixtures.png())
        let twice = try await Pipeline.defaultOptimize.run(once.bytes)
        #expect(twice.newSize <= twice.originalSize)
        #expect(twice.savedBytes >= 0)
    }

    @Test func sameFormatResultThatGrowsReturnsOriginalBytes() async throws {
        let input = Fixtures.jpeg(quality: 0.3)
        let pipeline = Pipeline(output: OutputSpec(options: EncodeOptions(quality: 100)))
        let result = try await pipeline.run(input)
        #expect(result.bytes == input)
        #expect(result.savedBytes == 0)
    }

    // Final review 1a: the never-larger fallback must still honour StripMetadata.
    @Test func neverLargerFallbackStillStripsGPS() async throws {
        let pipeline = Pipeline(
            operations: [StripMetadata(), Optimize()], output: OutputSpec(options: EncodeOptions(quality: 100)))
        for orientation in [1, 6] {
            let input = Fixtures.jpeg(orientation: orientation, quality: 0.3, gps: true)
            #expect(Fixtures.hasGPS(input))
            // Precondition: the q100 re-encode really is not smaller, so the guard falls back.
            var image = try JPEGCodec().decode(input)
            for operation in pipeline.operations { image = try operation.apply(image) }
            #expect(try JPEGCodec().encode(image, options: pipeline.output.options).count >= input.count)

            let result = try await pipeline.run(input)
            #expect(!Fixtures.hasGPS(result.bytes))
            #expect(result.newSize <= result.originalSize)
            #expect(result.newSize == result.bytes.count)
            #expect(try JPEGCodec().decode(result.bytes).orientation == orientation)
            #expect(try Fixtures.pixels(result.bytes) == Fixtures.pixels(input))  // lossless strip

            let optimized = try await Pipeline.defaultOptimize.run(input)
            #expect(optimized.newSize <= optimized.originalSize)
            #expect(!Fixtures.hasGPS(optimized.bytes))
        }
    }

    @Test func explicitResizeReturnsRequestedResultEvenIfLarger() async throws {
        let pipeline = Pipeline(operations: [Resize(.exact(width: 640, height: 480))])
        let result = try await pipeline.run(Fixtures.png())
        let decoded = try PNGCodec().decode(result.bytes)
        #expect(decoded.width == 640 && decoded.height == 480)
    }

    // MARK: Conversion

    @Test func convertsPngToWebpWithResize() async throws {
        let pipeline = Pipeline(
            operations: [Resize(.width(32)), StripMetadata(), Optimize()],
            output: OutputSpec(format: .webp, options: EncodeOptions(quality: 82)))
        let result = try await pipeline.run(Fixtures.png())
        #expect(result.format == .webp)
        let decoded = try WebPCodec().decode(result.bytes)
        #expect(decoded.width == 32 && decoded.height == 24)
    }

    // Review Focus 3: resize bakes orientation in and swaps dimensions.
    @Test func resizeBakesInExifOrientation() async throws {
        let input = Fixtures.jpeg(width: 64, height: 48, orientation: 6)
        let pipeline = Pipeline(operations: [Resize(.width(24))])
        let result = try await pipeline.run(input)
        let decoded = try JPEGCodec().decode(result.bytes)
        #expect(decoded.orientation == 1)
        #expect(decoded.width == 24 && decoded.height == 32)  // upright is 48x64
    }

    // MARK: Bad input (Review Focus 5)

    @Test func garbageInputThrowsTypedErrors() async {
        await #expect(throws: OptimosError.unsupportedFormat) {
            try await Pipeline.defaultOptimize.run(Data([1, 2, 3]))
        }
        let truncatedPNG = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0])
        await #expect(throws: OptimosError.self) {
            try await Pipeline.defaultOptimize.run(truncatedPNG)
        }
    }

    @Test func rejectsQualityOutOfRange() async {
        let pipeline = Pipeline(output: OutputSpec(options: EncodeOptions(quality: 0)))
        await #expect(throws: OptimosError.self) { try await pipeline.run(Fixtures.png()) }
    }
}
