import Foundation
import Testing

@testable import OptimosApp

@Suite struct ErrorMessageTests {
    @Test func usesTheDescriptionOfACaptureError() {
        #expect(ErrorMessage.text(for: CaptureError.displayNotFound) == "that display is no longer available")
    }

    @Test func usesTheDescriptionOfAnOutputError() {
        #expect(ErrorMessage.text(for: OutputError.encodeFailed) == "could not encode the screenshot as PNG")
        #expect(ErrorMessage.text(for: OutputError.cannotWrite("disk full")) == "could not save the screenshot: disk full")
    }

    @Test func usesTheLocalizedDescriptionOfAnyOtherError() {
        let error = NSError(domain: "x", code: 1, userInfo: [NSLocalizedDescriptionKey: "Boom"])
        #expect(ErrorMessage.text(for: error) == "Boom")
    }
}
