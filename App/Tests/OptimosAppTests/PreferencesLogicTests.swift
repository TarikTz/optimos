import Carbon.HIToolbox
import CoreGraphics
import Foundation
import OptimosCore
import Testing

@testable import OptimosApp

private func isolatedDefaults() -> (UserDefaults, () -> Void) {
    let name = "optimos-prefs-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    return (defaults, { defaults.removePersistentDomain(forName: name) })
}

@Suite struct ShortcutValidatorTests {
    private let control = UInt32(controlKey | optionKey | cmdKey)

    @Test func needsAModifier() {
        let key = Hotkey(keyCode: UInt32(kVK_ANSI_K), modifiers: 0, keyLabel: "K")
        #expect(ShortcutValidator.validate(key, for: .captureArea, in: [:]) == .needsModifier)
        let shiftOnly = Hotkey(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(shiftKey), keyLabel: "K")
        #expect(ShortcutValidator.validate(shiftOnly, for: .captureArea, in: [:]) == .needsModifier)
    }

    @Test func refusesMacOSCombinationsAndDuplicates() {
        let quit = Hotkey(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey), keyLabel: "Q")
        #expect(ShortcutValidator.validate(quit, for: .captureArea, in: [:]) == .reserved)
        let system = Hotkey(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey), keyLabel: "4")
        #expect(ShortcutValidator.validate(system, for: .captureArea, in: [:]) == .reserved)
        let taken = Hotkey.defaults[.captureScreen]!
        #expect(ShortcutValidator.validate(taken, for: .captureArea, in: Hotkey.defaults) == .duplicate(.captureScreen))
        #expect(ShortcutValidator.validate(taken, for: .captureScreen, in: Hotkey.defaults) == nil)
    }

    @Test func acceptsAnUnusedCombination() {
        let key = Hotkey(keyCode: UInt32(kVK_ANSI_K), modifiers: control, keyLabel: "K")
        #expect(ShortcutValidator.validate(key, for: .captureArea, in: Hotkey.defaults) == nil)
    }
}

@Suite struct SettingsStoreTests {
    @Test func hotkeyStoreStartsWithDefaultsAndRemembersChangesAndDisabling() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let store = HotkeyStore(defaults: defaults)
        #expect(store.table == Hotkey.defaults)
        var table = store.table
        table[.captureArea] = Hotkey(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(controlKey | cmdKey), keyLabel: "K")
        table[.captureScreen] = nil
        store.setTable(table)
        let reloaded = HotkeyStore(defaults: defaults).table
        #expect(reloaded == table)
        #expect(reloaded[.captureScreen] == nil)
        #expect(reloaded[.openOptimizer] == Hotkey.defaults[.openOptimizer])
    }

    @Test func hotkeyStoreFallsBackToDefaultsOnGarbage() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        defaults.set(Data("not json".utf8), forKey: "hotkeyBindings")
        #expect(HotkeyStore(defaults: defaults).table == Hotkey.defaults)
    }

    @Test func captureSettingsDefaultToLosslessPNGAndRoundTrip() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let store = CaptureSettingsStore(defaults: defaults)
        #expect(store.format == .png && store.level == .lossless)
        store.format = .webp
        store.level = .smallest
        #expect(CaptureSettingsStore(defaults: defaults).format == .webp)
        #expect(CaptureSettingsStore(defaults: defaults).level == .smallest)
    }

    @Test func optimizerSettingsRoundTripAndTolerateGarbage() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let store = OptimizerSettingsStore(defaults: defaults)
        #expect(store.settings == OptimizeSettings())
        store.settings = OptimizeSettings(level: .smallest, format: .jpeg, maxSide: 800, keepMetadata: true, replaceOriginals: false)
        #expect(OptimizerSettingsStore(defaults: defaults).settings.replaceOriginals == false)
        defaults.set(Data("nope".utf8), forKey: "optimizerSettings")
        #expect(OptimizerSettingsStore(defaults: defaults).settings == OptimizeSettings())
    }
}

@Suite struct CaptureFormatOutputTests {
    private func image() -> CGImage {
        let ctx = CGContext(
            data: nil, width: 200, height: 120, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 120))
        return ctx.makeImage()!
    }

    @Test func saveUsesTheCaptureFormatAndExtensionButCopyStaysPNG() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-fmt-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let board = FakePasteboard()
        let service = OutputService(
            pasteboard: board, saveDirectory: { dir }, captureSettings: { (.webp, .balanced) })
        let saved = try await service.save(image())
        guard case .file(let url) = saved.destination else { Issue.record("no file"); return }
        #expect(url.pathExtension == "webp")
        #expect(ImageFormat.sniff(try Data(contentsOf: url)) == .webp)
        _ = try await service.copy(image())
        #expect(ImageFormat.sniff(try #require(board.written.first)) == .png)
    }

    @Test func aFailedOptimizerStillSavesAPlainPNGWithAPNGName() async throws {
        struct Boom: Error {}
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-fmt-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let service = OutputService(
            pasteboard: FakePasteboard(), saveDirectory: { dir }, captureSettings: { (.webp, .balanced) },
            optimizer: { _, _ in throw Boom() })
        let saved = try await service.save(image())
        guard case .file(let url) = saved.destination else { Issue.record("no file"); return }
        #expect(url.pathExtension == "png")
        #expect(saved.warning != nil)
    }
}
