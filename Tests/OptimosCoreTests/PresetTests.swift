import Foundation
import Testing
@testable import OptimosCore

@Suite struct PresetTests {
    private func tempStore() -> PresetStore {
        PresetStore(url: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathComponent("presets.json"))
    }

    @Test func builtInsMatchThePRD() throws {
        let byName = Dictionary(uniqueKeysWithValues: Preset.builtIns.map { ($0.name, $0) })
        let website = try #require(byName["Website"])
        #expect(website.format == .webp && website.quality == 82 && website.maxWidth == 1600 && website.stripMetadata)
        let screenshot = try #require(byName["Screenshot"])
        #expect(screenshot.format == .png && screenshot.quality == nil)
        let github = try #require(byName["GitHub"])
        #expect(github.format == .webp && github.maxWidth == 2000 && github.quality == 85)
        let slack = try #require(byName["Slack"])
        #expect(slack.format == .jpeg && slack.quality == 80 && slack.maxWidth == 1600)
    }

    @Test func websitePresetProducesAWebpWithoutUpscaling() async throws {
        let website = try #require(Preset.builtIns.first { $0.name == "Website" })
        let result = try await website.pipeline().run(Fixtures.png(width: 64, height: 48))
        #expect(result.format == .webp)
        let decoded = try WebPCodec().decode(result.bytes)
        #expect(decoded.width == 64 && decoded.height == 48)  // 64 < 1600, so untouched
    }

    @Test func storeRoundTripsCustomPresetsAndFindsCaseInsensitively() throws {
        let store = tempStore()
        #expect(try store.customPresets().isEmpty)  // missing file is fine
        let mine = Preset(name: "Blog", format: .webp, quality: 70, maxWidth: 1200)
        try store.add(mine)
        #expect(try store.customPresets() == [mine])
        #expect(try store.preset(named: "blog") == mine)
        #expect(try store.preset(named: "website")?.name == "Website")
        #expect(try store.all().count == Preset.builtIns.count + 1)
    }

    @Test func storeRejectsBuiltInNames() {
        #expect(throws: OptimosError.self) {
            try tempStore().add(Preset(name: "website"))
        }
    }

    @Test func badBackgroundHexIsRejected() {
        let preset = Preset(name: "x", format: .jpeg, backgroundHex: "zzz")
        #expect(throws: OptimosError.self) { try preset.pipeline() }
    }
}
