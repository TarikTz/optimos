import Foundation
import Testing
@testable import OptimosCore

/// A PNG whose header claims `width` × `height` pixels but which holds no pixel data at all.
private func bombPNG(width: UInt32, height: UInt32) -> Data {
    func crc32(_ bytes: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB8_8320 : crc >> 1 }
        }
        return ~crc
    }
    func be(_ v: UInt32) -> [UInt8] { [UInt8(v >> 24), UInt8((v >> 16) & 255), UInt8((v >> 8) & 255), UInt8(v & 255)] }
    func chunk(_ type: String, _ body: [UInt8]) -> [UInt8] {
        let typed = Array(type.utf8) + body
        return be(UInt32(body.count)) + typed + be(crc32(typed))
    }
    let header = be(width) + be(height) + [8, 6, 0, 0, 0]
    return Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] + chunk("IHDR", header) + chunk("IEND", []))
}

@Suite struct ImageLimitsTests {
    @Test func rejectsHugeDimensionsAndAcceptsNormalOnes() throws {
        try ImageLimits.check(width: 8000, height: 6000)  // a 48 megapixel photo is fine
        #expect(throws: OptimosError.imageTooLarge(width: 40_000, height: 40_000)) {
            try ImageLimits.check(width: 40_000, height: 40_000)
        }
        #expect(throws: OptimosError.self) { try ImageLimits.check(width: 31_000, height: 100) }  // too long a side
        #expect(throws: OptimosError.self) { try ImageLimits.check(width: 20_000, height: 20_000) }  // 400 MP
        #expect(throws: OptimosError.self) { try ImageLimits.check(width: Int.max, height: 2) }  // overflow
    }

    @Test func aTinyFileDeclaringAHugeSizeIsRefusedBeforeDecoding() async throws {
        let data = bombPNG(width: 40_000, height: 40_000)
        #expect(data.count < 100)
        await #expect(throws: OptimosError.imageTooLarge(width: 40_000, height: 40_000)) {
            _ = try await Pipeline.defaultOptimize.run(data)
        }
    }

    @Test func fileJobRefusesItAndLeavesTheFileAlone() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-limit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("bomb.png")
        let bomb = bombPNG(width: 40_000, height: 40_000)
        try bomb.write(to: file)
        await #expect(throws: OptimosError.self) { _ = try await FileJob.run(file, settings: .init()) }
        #expect(try Data(contentsOf: file) == bomb)
    }
}

@Suite struct ToolHardeningTests {
    @Test func aHungToolIsStoppedAtTheTimeout() {
        let tool = ExternalTool(name: "sleep", searchPaths: ["/bin"])
        let started = Date()
        #expect(throws: OptimosError.self) { try tool.run(["30"], input: Data(), timeout: 0.4) }
        #expect(Date().timeIntervalSince(started) < 5)
    }

    @Test func cancellingTheTaskStopsARunningTool() async {
        let started = Date()
        let task = Task.detached {
            try? ExternalTool(name: "sleep", searchPaths: ["/bin"]).run(["30"], input: Data())
        }
        try? await Task.sleep(for: .milliseconds(300))
        task.cancel()
        _ = await task.value
        #expect(Date().timeIntervalSince(started) < 5)
    }

    @Test func toolsRunWithACleanEnvironment() throws {
        setenv("DYLD_INSERT_LIBRARIES", "/nonexistent.dylib", 1)
        setenv("OPTIMOS_SECRET_TEST", "leak", 1)
        defer {
            unsetenv("DYLD_INSERT_LIBRARIES")
            unsetenv("OPTIMOS_SECRET_TEST")
        }
        let result = try ExternalTool(name: "env", searchPaths: ["/usr/bin"]).run([], input: Data())
        let text = String(decoding: result.output, as: UTF8.self)
        #expect(!text.contains("DYLD_"))
        #expect(!text.contains("OPTIMOS_SECRET_TEST"))
        #expect(text.contains("PATH=/usr/bin:/bin"))
    }

    @Test func theToolsDirectoryVariableIsOnlyHonouredOutsideAnAppBundle() {
        // Tests run from a command-line bundle, so the variable still applies here.
        #expect(!Bundle.main.bundlePath.hasSuffix(".app"))
        #expect(ExternalTool.toolsDirectory(from: ["OPTIMOS_TOOLS_DIR": "/opt/x"]) == "/opt/x")
        #expect(!ExternalTool.defaultSearchPaths.contains("/usr/local/bin"))
    }
}

@Suite struct FileSafetyTests {
    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-safe-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func aSymlinkedFileIsUpdatedWhereItLivesAndStaysALink() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let real = dir.appendingPathComponent("real.png")
        let link = dir.appendingPathComponent("link.png")
        let original = Fixtures.png(width: 400, height: 300)
        try original.write(to: real)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        let result = try await FileJob.run(link, settings: .init(level: .balanced))
        #expect(result.outcome == .replaced)
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) != nil)  // still a symlink
        #expect(try Data(contentsOf: real).count < original.count)
    }

    @Test func noBackupCanBeMadeAfterTheSessionEnded() throws {
        let dir = try tempDir()
        let backups = dir.appendingPathComponent("backups")
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        try Data("x".utf8).write(to: file)
        let store = BackupStore(directory: backups)
        store.deleteAll()
        #expect(throws: (any Error).self) { try store.backUp(file) }
        #expect(!FileManager.default.fileExists(atPath: backups.path))  // no orphan folder
    }

    @Test func transparencyIsStillDetectedExactly() {
        #expect(Pixels.hasTransparency(Fixtures.cgImage(transparent: true)))
        #expect(!Pixels.hasTransparency(Fixtures.cgImage(transparent: false)))
    }
}
