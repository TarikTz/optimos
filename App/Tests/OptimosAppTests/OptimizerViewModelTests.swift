import AppKit
import Foundation
import Testing

@testable import OptimosApp

@MainActor
@Suite struct OptimizerViewModelTests {
    private func png() -> Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 300, pixelsHigh: 200, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        for x in 0..<300 {
            for y in 0..<200 {
                rep.setColor(NSColor(red: CGFloat(x) / 300, green: CGFloat(y) / 200, blue: CGFloat((x * y) % 255) / 255, alpha: 1), atX: x, y: y)
            }
        }
        return rep.representation(using: .png, properties: [:])!
    }

    private func waitUntilIdle(_ model: OptimizerViewModel) async {
        for _ in 0..<200 where model.isWorking { try? await Task.sleep(for: .milliseconds(50)) }
    }

    @Test func droppedFileIsOptimizedAndUndoRestoresIt() async throws {
        let suite = "optimos-vm-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("optimos-vm-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("a.png")
        let original = png()
        try original.write(to: file)

        let model = OptimizerViewModel(defaults: defaults)
        defer { model.close() }
        model.add([file, file])  // the duplicate is ignored
        #expect(model.rows.count == 1)
        await waitUntilIdle(model)
        guard case .done = model.rows[0].status else { Issue.record("not done: \(model.rows[0].status)"); return }
        #expect(try Data(contentsOf: file).count < original.count)

        model.undo()
        #expect(try Data(contentsOf: file) == original)
        #expect(model.rows[0].status == .restored)
    }

    @Test func settingsAreRemembered() {
        let suite = "optimos-vm-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = OptimizerViewModel(defaults: defaults)
        model.settings = .init(level: .smallest, format: .webp, maxSide: 1920)
        defer { model.close() }
        let again = OptimizerViewModel(defaults: defaults)
        defer { again.close() }
        #expect(again.settings == .init(level: .smallest, format: .webp, maxSide: 1920))
    }
}
