import Foundation
import OptimosCore
import Testing

@testable import OptimosApp

@Suite struct AppSmokeTests {
    @Test func appIsMenuBarOnly() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
    }

    @Test func screenCaptureUsageDescriptionIsPresent() {
        let text = Bundle.main.object(forInfoDictionaryKey: "NSScreenCaptureUsageDescription") as? String
        #expect(text?.isEmpty == false)
    }

    @Test func optimosCoreIsLinkedIntoTheApp() {
        #expect(Preset.builtIns.count == 4)
        #expect(ImageFormat.sniff(Data([0xFF, 0xD8, 0xFF])) == .jpeg)
    }
}
