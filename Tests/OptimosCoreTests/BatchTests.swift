import Foundation
import ImageIO
import Testing
@testable import OptimosCore

private func tempDir() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-batch-\(UUID().uuidString)")
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private final class Calls: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    func add(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    var all: [URL] { lock.lock(); defer { lock.unlock() }; return urls }
}

private func size(of data: Data) -> (Int, Int) {
    let src = CGImageSourceCreateWithData(data as CFData, nil)!
    let p = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as! [CFString: Any]
    return (p[kCGImagePropertyPixelWidth] as! Int, p[kCGImagePropertyPixelHeight] as! Int)
}

@Suite struct OptimizeSettingsTests {
    @Test func levelsMapToTheDocumentedNumbers() {
        #expect(OptimizeSettings(level: .balanced).options(for: .jpeg, reencodes: false).quality == 82)
        #expect(OptimizeSettings(level: .balanced).options(for: .webp, reencodes: false).quality == 80)
        #expect(OptimizeSettings(level: .balanced).options(for: .png, reencodes: false).quantizeQuality == 65...85)
        #expect(OptimizeSettings(level: .smallest).options(for: .jpeg, reencodes: false).quality == 70)
        #expect(OptimizeSettings(level: .smallest).options(for: .png, reencodes: false).quantizeQuality == 40...65)
        #expect(OptimizeSettings(level: .lossless).options(for: .webp, reencodes: false).lossless)
    }

    @Test func losslessJPEGStaysOnTheLosslessPathUnlessReencoding() {
        let s = OptimizeSettings(level: .lossless)
        #expect(s.options(for: .jpeg, reencodes: false).quality == nil)
        #expect(s.options(for: .jpeg, reencodes: true).quality == 95)
    }
}

@Suite struct FileJobTests {
    @Test func replacesAFileInPlaceWhenSmaller() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        let original = Fixtures.png(width: 400, height: 300)
        try original.write(to: file)
        let calls = Calls()
        let result = try await FileJob.run(file, settings: .init(level: .balanced), willReplace: { calls.add($0) })
        #expect(result.outcome == .replaced)
        #expect(calls.all == [file])
        #expect(try Data(contentsOf: file).count < original.count)
        #expect(result.newBytes == (try Data(contentsOf: file)).count)
    }

    @Test func leavesAnAlreadyOptimalFileUntouched() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        try Fixtures.png(width: 100, height: 80).write(to: file)
        _ = try await FileJob.run(file, settings: .init(level: .lossless))
        let after = try Data(contentsOf: file)
        let calls = Calls()
        let again = try await FileJob.run(file, settings: .init(level: .lossless), willReplace: { calls.add($0) })
        #expect(again.outcome == .alreadyOptimal)
        #expect(calls.all.isEmpty)
        #expect(try Data(contentsOf: file) == after)
    }

    @Test func convertingWritesANewFileAndKeepsTheOriginal() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        let original = Fixtures.png(width: 200, height: 150)
        try original.write(to: file)
        try Data("occupied".utf8).write(to: dir.appendingPathComponent("a.jpg"))
        let result = try await FileJob.run(file, settings: .init(level: .balanced, format: .jpeg))
        guard case .converted(let output) = result.outcome else { Issue.record("not converted"); return }
        #expect(output.lastPathComponent == "a 2.jpg")  // a.jpg already existed and is not overwritten
        #expect(ImageFormat.sniff(try Data(contentsOf: output)) == .jpeg)
        #expect(try Data(contentsOf: file) == original)
        #expect(try Data(contentsOf: dir.appendingPathComponent("a.jpg")) == Data("occupied".utf8))
    }

    @Test func shrinksOnlyImagesLargerThanTheLimit() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let big = dir.appendingPathComponent("big.png")
        let small = dir.appendingPathComponent("small.png")
        try Fixtures.png(width: 400, height: 200).write(to: big)
        try Fixtures.png(width: 60, height: 40).write(to: small)
        let settings = OptimizeSettings(level: .lossless, maxSide: 100)
        _ = try await FileJob.run(big, settings: settings)
        _ = try await FileJob.run(small, settings: settings)
        #expect(size(of: try Data(contentsOf: big)) == (100, 50))
        #expect(size(of: try Data(contentsOf: small)) == (60, 40))
    }

    @Test func unsupportedFileFailsAndStaysUntouched() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("notes.png")
        try Data("not an image".utf8).write(to: file)
        await #expect(throws: OptimosError.unsupportedFormat) {
            _ = try await FileJob.run(file, settings: .init())
        }
        #expect(try Data(contentsOf: file) == Data("not an image".utf8))
    }

    @Test func aFailingBackupStopsTheReplace() async throws {
        struct Boom: Error {}
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        let original = Fixtures.png(width: 400, height: 300)
        try original.write(to: file)
        await #expect(throws: Boom.self) {
            _ = try await FileJob.run(file, settings: .init(), willReplace: { _ in throw Boom() })
        }
        #expect(try Data(contentsOf: file) == original)
    }
}

@Suite struct BackupStoreTests {
    @Test func restoreBringsOriginalsBackAndRemovesConvertedFiles() throws {
        let dir = tempDir()
        let store = BackupStore(directory: tempDir())
        defer { try? FileManager.default.removeItem(at: dir); store.deleteAll() }
        let file = dir.appendingPathComponent("a.png")
        try Data("original".utf8).write(to: file)
        try store.backUp(file)
        try Data("changed".utf8).write(to: file)
        try store.backUp(file)  // second call must not overwrite the first backup
        let converted = dir.appendingPathComponent("a.webp")
        try Data("new".utf8).write(to: converted)
        store.recordCreated(converted)
        #expect(store.restoreAll().isEmpty)
        #expect(try Data(contentsOf: file) == Data("original".utf8))
        #expect(!FileManager.default.fileExists(atPath: converted.path))
    }

    @Test func deleteAllRemovesTheBackupFolder() throws {
        let backups = tempDir()
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = BackupStore(directory: backups)
        let file = dir.appendingPathComponent("a.png")
        try Data("x".utf8).write(to: file)
        try store.backUp(file)
        store.deleteAll()
        #expect(!FileManager.default.fileExists(atPath: backups.path))
    }
}

@Suite struct ImageFileScannerTests {
    @Test func foldersYieldSupportedVisibleImagesAndNamedFilesAreKept() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        for name in ["a.PNG", "b.txt", ".hidden.png", "sub/c.webp"] {
            try Data("x".utf8).write(to: dir.appendingPathComponent(name))
        }
        let named = dir.appendingPathComponent("b.txt")
        let urls = ImageFileScanner.imageURLs(from: [dir, named, dir.appendingPathComponent("a.PNG")])
        #expect(urls.map(\.lastPathComponent) == ["a.PNG", "c.webp", "b.txt"])
    }
}

@Suite struct SettingsOptionsTests {
    @Test func settingsStoredByAnOlderVersionStillDecode() throws {
        let old = Data(#"{"level":"smallest","maxSide":1280}"#.utf8)
        let decoded = try JSONDecoder().decode(OptimizeSettings.self, from: old)
        #expect(decoded == OptimizeSettings(level: .smallest, format: nil, maxSide: 1280))
        #expect(decoded.replaceOriginals && !decoded.keepMetadata)
    }

    @Test func copyModeLeavesTheOriginalAndWritesAnOptimizedCopy() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        let original = Fixtures.png(width: 400, height: 300)
        try original.write(to: file)
        try Data("x".utf8).write(to: dir.appendingPathComponent("a-optimized.png"))
        let settings = OptimizeSettings(level: .balanced, replaceOriginals: false)
        let result = try await FileJob.run(file, settings: settings)
        guard case .converted(let output) = result.outcome else { Issue.record("no copy"); return }
        #expect(output.lastPathComponent == "a-optimized 2.png")
        #expect(try Data(contentsOf: file) == original)
        #expect(try Data(contentsOf: dir.appendingPathComponent("a-optimized.png")) == Data("x".utf8))
    }

    @Test func keepMetadataKeepsGPSAndRemoveDropsIt() async throws {
        let input = Fixtures.jpeg(gps: true)
        let kept = try await OptimizeSettings(level: .lossless, keepMetadata: true).process(input)
        let removed = try await OptimizeSettings(level: .lossless).process(input)
        #expect(Fixtures.hasGPS(kept.bytes))
        #expect(!Fixtures.hasGPS(removed.bytes))
    }

    @Test func processReturnsTheRequestedFormat() async throws {
        let out = try await OptimizeSettings(level: .balanced, format: .webp).process(Fixtures.png())
        #expect(out.format == .webp)
        #expect(ImageFormat.sniff(out.bytes) == .webp)
    }
}
