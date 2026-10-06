import AppKit
import SwiftUI

enum ToastSizing {
    /// The panel size for a message: the intrinsic width (capped by `ToastView.maxWidth`) and a height
    /// that accounts for wrapping at that width. `NSHostingView.fittingSize` alone reports a
    /// one-line height for a long message, which clips the wrapped text.
    @MainActor
    static func size(for message: String, isWarning: Bool) -> NSSize {
        let view = ToastView(message: message, isWarning: isWarning)
        let width = NSHostingView(rootView: view).fittingSize.width
        let controller = NSHostingController(rootView: view)
        let height = controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return NSSize(width: width, height: height)
    }
}
