import CoreGraphics
import Foundation
import OptimosCore
import Testing

@testable import OptimosApp

final class FakePasteboard: Pasteboard, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Data] = []
    var written: [Data] { lock.withLock { storage } }
    func writePNG(_ data: Data) { lock.withLock { storage.append(data) } }
}

private struct StubError: Error {}

private func makeImage(width: Int = 64, height: Int = 48) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let base = context.data!.assumingMemoryBound(to: UInt8.self)
    for y in 0..<height {
        for x in 0..<width {
            let o = y * context.bytesPerRow + x * 4
            base[o] = UInt8(x * 255 / max(width - 1, 1))
            base[o + 1] = UInt8(y * 255 / max(height - 1, 1))
            base[o + 2] = UInt8((x * y) % 256)
            base[o + 3] = 255
        }
    }
    return context.makeImage()!
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("optimos-tests-\(UUID().uuidString)")
}

@Suite struct OutputServiceTests {
    @Test func copyWritesTheOptimizedBytesToTheClipboard() async throws {
        let board = FakePasteboard()
        let service = OutputService(pasteboard: board, optimizer: { _ in Data("OPT".utf8) })
        let result = try await service.copy(makeImage())
        #expect(board.written == [Data("OPT".utf8)])
        #expect(result.destination == .clipboard)
        #expect(result.finalBytes == 3)
        #expect(result.warning == nil)
        #expect(result.toastMessage.hasPrefix("Copied ·"))
    }

    @Test func copyFallsBackToThePlainPNGAndSaysSo() async throws {
        let board = FakePasteboard()
        let service = OutputService(pasteboard: board, optimizer: { _ in throw StubError() })
        let result = try await service.copy(makeImage())
        #expect(ImageFormat.sniff(try #require(board.written.first)) == .png)
        #expect(result.warning?.hasPrefix("not optimized") == true)
        #expect(result.toastMessage.contains("not optimized"))
    }

    @Test func saveWritesAFileNamedFromTheClock() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { directory },
            optimizer: { _ in Data("OPT".utf8) }, now: { date })

        let first = try await service.save(makeImage())
        guard case .file(let firstURL) = first.destination else {
            Issue.record("expected a file destination")
            return
        }
        #expect(firstURL.lastPathComponent == ScreenshotFilename.make(for: date))
        #expect(try Data(contentsOf: firstURL) == Data("OPT".utf8))

        // A second capture in the same second must not overwrite the first.
        let second = try await service.save(makeImage())
        guard case .file(let secondURL) = second.destination else {
            Issue.record("expected a file destination")
            return
        }
        #expect(secondURL != firstURL)
        #expect(secondURL.lastPathComponent.hasSuffix(" 2.png"))
        #expect(FileManager.default.fileExists(atPath: firstURL.path))
    }

    @Test func saveToastNamesTheFolderAndTheFile() async throws {
        let directory = temporaryDirectory().appendingPathComponent("Shots")
        defer { try? FileManager.default.removeItem(at: directory.deletingLastPathComponent()) }
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { directory },
            optimizer: { _ in Data("OPT".utf8) }, now: { Date(timeIntervalSince1970: 1_800_000_000) })
        let result = try await service.save(makeImage())
        #expect(result.toastMessage.hasPrefix("Saved to Shots · "))
        #expect(result.toastMessage.contains(ScreenshotFilename.make(for: Date(timeIntervalSince1970: 1_800_000_000))))
    }

    @Test func savingToAnUnwritableLocationThrowsCannotWrite() async throws {
        // A path whose parent is a regular file can never become a directory.
        let blocker = temporaryDirectory()
        try Data("x".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { blocker.appendingPathComponent("sub") },
            optimizer: { _ in Data("OPT".utf8) })
        await #expect(throws: OutputError.self) { try await service.save(makeImage()) }
    }

    /// Needs the optimizer tools from the README (oxipng) installed.
    @Test func realScreenshotOptimizerReturnsAValidPNGNoLargerThanTheInput() async throws {
        let png = try PNGEncoder.data(from: makeImage())
        let optimized = try await OutputService.screenshotOptimizer(png)
        #expect(ImageFormat.sniff(optimized) == .png)
        #expect(optimized.count <= png.count)
    }
}
