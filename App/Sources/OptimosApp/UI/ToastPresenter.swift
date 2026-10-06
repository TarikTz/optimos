import AppKit
import SwiftUI

struct ToastView: View {
    let message: String
    let isWarning: Bool

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isWarning ? Color.orange : Color.primary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: Self.maxWidth)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(8)
    }

    /// Long messages wrap at this width instead of running off both screen edges.
    static let maxWidth: CGFloat = 480
}

@MainActor
final class ToastPresenter {
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    func show(_ message: String, isWarning: Bool = false, duration: TimeInterval = 2.2) {
        hideTask?.cancel()
        panel?.orderOut(nil)

        let host = NSHostingView(rootView: ToastView(message: message, isWarning: isWarning))
        let size = host.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false

        if let screen = NSScreen.containingMouse() ?? NSScreen.main {
            let area = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2, y: area.minY + 72))
        }
        panel.orderFrontRegardless()
        self.panel = panel

        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.panel?.orderOut(nil)
            self?.panel = nil
        }
    }
}
