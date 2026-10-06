import AppKit
import SwiftUI
import Testing

@testable import OptimosApp

@MainActor
@Suite struct ToastSizingTests {
    private let longMessage = String(repeating: "NSURLErrorDomain something went wrong ", count: 12)

    @Test func aShortMessageStaysCompactOnOneLine() {
        let size = ToastSizing.size(for: "Copied", isWarning: false)
        #expect(size.width < 200)
        #expect(size.height < 60)
    }

    @Test func aLongMessageIsCappedInWidthAndTallerThanOneLine() {
        let oneLine = ToastSizing.size(for: "Copied", isWarning: false).height
        let size = ToastSizing.size(for: longMessage, isWarning: true)
        #expect(size.width <= ToastView.maxWidth + 16)  // cap plus the 8pt outer padding on each side
        // Wrapped onto about three lines: clearly taller than a single line, so nothing is clipped.
        #expect(size.height > oneLine + 20)
    }

    @Test func aMediumMessageWrapsToTwoLines() {
        let oneLine = ToastSizing.size(for: "Copied", isWarning: false).height
        let message = "Saved to Optimos · Optimos 2026-10-06 at 13.42.11.png · 2.8 MB → 1.1 MB"
        let size = ToastSizing.size(for: message, isWarning: false)
        #expect(size.height > oneLine + 8)
    }
}
