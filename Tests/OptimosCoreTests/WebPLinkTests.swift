import Testing
@testable import OptimosCore

@Suite struct WebPLinkTests {
    @Test func staticLibwebpIsLinked() {
        #expect(WebPLibrary.encoderVersion > 0)
    }
}
