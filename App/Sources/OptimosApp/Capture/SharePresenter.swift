import AppKit

/// Shows the macOS share menu for a file, anchored where the capture toolbar was. The menu needs a
/// view to hang from, so a tiny invisible window stands in for the closed overlay.
@MainActor
final class SharePresenter: NSObject, NSSharingServicePickerDelegate {
    private var anchor: NSPanel?
    private var picker: NSSharingServicePicker?

    /// - Parameter anchorRect: in AppKit screen coordinates (bottom-left origin).
    func share(_ file: URL, near anchorRect: CGRect) {
        close()
        let panel = NSPanel(
            contentRect: CGRect(x: anchorRect.midX - 1, y: anchorRect.midY - 1, width: 2, height: 2),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 2, height: 2))
        anchor = panel
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        let picker = NSSharingServicePicker(items: [file])
        picker.delegate = self
        self.picker = picker
        picker.show(relativeTo: panel.contentView!.bounds, of: panel.contentView!, preferredEdge: .maxY)
    }

    private func close() {
        anchor?.orderOut(nil)
        anchor = nil
        picker = nil
    }

    // Called when the user picks a service, or nil when the menu is dismissed.
    nonisolated func sharingServicePicker(
        _ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?
    ) {
        // Keep the anchor alive a moment so the chosen service can still use it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            MainActor.assumeIsolated { self?.close() }
        }
    }
}
