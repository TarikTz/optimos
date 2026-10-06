import AppKit

/// The small Copy / Save / Cancel bar shown next to a confirmed selection. It is where annotation
/// tools will be added later.
@MainActor
final class OverlayToolbar: NSVisualEffectView {
    static let size = CGSize(width: 128, height: 36)

    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?

    init() {
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        let stack = NSStackView(views: [
            makeButton(symbol: "doc.on.clipboard", tip: "Copy (Enter)", action: #selector(didTapCopy)),
            makeButton(symbol: "square.and.arrow.down", tip: "Save (⌘S)", action: #selector(didTapSave)),
            makeButton(symbol: "xmark", tip: "Cancel (Esc)", action: #selector(didTapCancel)),
        ])
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        stack.frame = bounds
        stack.autoresizingMask = [.width, .height]
        addSubview(stack)
    }

    required init?(coder: NSCoder) { fatalError("OverlayToolbar is created in code only") }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    private func makeButton(symbol: String, tip: String, action: Selector) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tip) ?? NSImage()
        let button = NSButton(image: image, target: self, action: action)
        button.isBordered = false
        button.contentTintColor = .white
        button.toolTip = tip
        button.refusesFirstResponder = true  // keep keyboard focus on the overlay view
        return button
    }

    @objc private func didTapCopy() { onCopy?() }
    @objc private func didTapSave() { onSave?() }
    @objc private func didTapCancel() { onCancel?() }
}
