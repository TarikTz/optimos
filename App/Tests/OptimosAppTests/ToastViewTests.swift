import AppKit
import SwiftUI
import Testing

@testable import OptimosApp

@MainActor
@Suite struct ToastViewTests {
    @Test func aLongMessageWrapsInsteadOfGrowingPastTheCap() {
        let long = String(repeating: "NSURLErrorDomain something went wrong ", count: 12)
        let host = NSHostingView(rootView: ToastView(message: long, isWarning: true))
        let size = host.fittingSize
        #expect(size.width <= ToastView.maxWidth + 16)  // cap plus the 8pt outer padding on each side
        #expect(size.height > 40)  // wrapped onto several lines
    }

    @Test func aShortMessageStaysCompact() {
        let host = NSHostingView(rootView: ToastView(message: "Copied", isWarning: false))
        #expect(host.fittingSize.width < 200)
    }
}
