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
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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

    @Test func savingToAMissingCustomFolderThrowsAndCreatesNothing() async throws {
        let parent = temporaryDirectory()
        let missing = parent.appendingPathComponent("missing")
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { missing }, optimizer: { _ in Data("OPT".utf8) })
        do {
            _ = try await service.save(makeImage())
            Issue.record("expected cannotWrite")
        } catch let error as OutputError {
            guard case .cannotWrite = error else {
                Issue.record("expected cannotWrite")
                return
            }
            #expect(error.description.contains(missing.path))
        }
        #expect(!FileManager.default.fileExists(atPath: missing.path))
        #expect(!FileManager.default.fileExists(atPath: parent.path))
    }

    @Test func savingToAnUnpluggedDriveThrowsAndDoesNotCreateTheMountPoint() async throws {
        let mount = "/Volumes/optimos-no-such-drive-\(UUID().uuidString)"
        let folder = URL(fileURLWithPath: mount).appendingPathComponent("Shots")
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { folder }, optimizer: { _ in Data("OPT".utf8) })
        await #expect(throws: OutputError.self) { try await service.save(makeImage()) }
        #expect(!FileManager.default.fileExists(atPath: mount))
    }

    @Test func saveDirectoryIsReadAtSaveTime() async throws {
        final class Box: @unchecked Sendable {
            private let lock = NSLock()
            private var url: URL
            init(_ url: URL) { self.url = url }
            var value: URL {
                get { lock.withLock { url } }
                set { lock.withLock { url = newValue } }
            }
        }
        let first = temporaryDirectory()
        let second = temporaryDirectory()
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let box = Box(first)
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { box.value }, optimizer: { _ in Data("OPT".utf8) })
        let a = try await service.save(makeImage())
        box.value = second
        let b = try await service.save(makeImage())
        guard case .file(let urlA) = a.destination, case .file(let urlB) = b.destination else {
            Issue.record("expected file destinations")
            return
        }
        #expect(urlA.deletingLastPathComponent().standardizedFileURL == first.standardizedFileURL)
        #expect(urlB.deletingLastPathComponent().standardizedFileURL == second.standardizedFileURL)
    }

    @Test func onlyTheDefaultFolderIsAutoCreated() {
        #expect(!OutputService.requiresExistingFolder(SaveLocationStore.defaultDirectory))
        #expect(OutputService.requiresExistingFolder(temporaryDirectory()))
    }

    /// Needs the optimizer tools from the README (oxipng) installed.
    @Test func realScreenshotOptimizerReturnsAValidPNGNoLargerThanTheInput() async throws {
        let png = try PNGEncoder.data(from: makeImage())
        let optimized = try await OutputService.screenshotOptimizer(png)
        #expect(ImageFormat.sniff(optimized) == .png)
        #expect(optimized.count <= png.count)
    }
}
