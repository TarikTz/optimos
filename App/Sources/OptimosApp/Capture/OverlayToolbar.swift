import AppKit

/// The bar shown next to a confirmed selection: annotation tools, colour and size pickers, then
/// Copy / Save / Cancel.
@MainActor
final class OverlayToolbar: NSVisualEffectView {
    private static let button: CGFloat = 24
    private static let swatch: CGFloat = 18
    private static let spacing: CGFloat = 4
    private static let inset: CGFloat = 10
    private static let toolCount = 5
    private static let swatchCount = 6
    private static let sizeCount = 3
    private static let actionCount = 3
    private static let separators = 3

    /// Derived from the same constants that lay the bar out, so placement always knows the real size.
    static let size: CGSize = {
        let buttons = CGFloat(toolCount + sizeCount + actionCount) * button
        let swatches = CGFloat(swatchCount) * swatch
        let elements = toolCount + swatchCount + sizeCount + actionCount + separators
        return CGSize(
            width: buttons + swatches + CGFloat(separators) + CGFloat(elements - 1) * spacing + 2 * inset,
            height: 36)
    }()

    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onTool: ((AnnotationTool) -> Void)?
    var onColor: ((AnnotationColor) -> Void)?
    var onSize: ((AnnotationSize) -> Void)?

    private var toolButtons: [AnnotationTool: NSButton] = [:]
    private var colorButtons: [AnnotationColor: NSButton] = [:]
    private var sizeButtons: [AnnotationSize: NSButton] = [:]
    private var tool: AnnotationTool
    private var color: AnnotationColor
    private var size: AnnotationSize

    init(tool: AnnotationTool = .select, color: AnnotationColor = .red, size: AnnotationSize = .medium) {
        self.tool = tool
        self.color = color
        self.size = size
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        var views: [NSView] = []
        let tools: [(AnnotationTool, String, String)] = [
            (.select, "cursorarrow", "Select and move (V)"),
            (.rectangle, "rectangle", "Rectangle (R)"),
            (.arrow, "arrow.up.right", "Arrow (A)"),
            (.text, "textformat", "Text (T)"),
            (.pixelate, "square.grid.3x3.fill", "Hide sensitive content (P)"),
        ]
        for (tool, symbol, tip) in tools {
            let button = makeButton(
                image: NSImage(systemSymbolName: symbol, accessibilityDescription: tip) ?? NSImage(), tip: tip,
                side: Self.button, action: #selector(didTapTool(_:)))
            button.tag = AnnotationTool.allCases.firstIndex(of: tool) ?? 0
            toolButtons[tool] = button
            views.append(button)
        }
        views.append(makeSeparator())
        for (index, color) in AnnotationColor.allCases.enumerated() {
            let button = makeButton(
                image: NSImage(), tip: "Colour", side: Self.swatch, action: #selector(didTapColor(_:)))
            button.tag = index
            colorButtons[color] = button
            views.append(button)
        }
        views.append(makeSeparator())
        for (index, size) in AnnotationSize.allCases.enumerated() {
            let button = makeButton(
                image: NSImage(), tip: "Size", side: Self.button, action: #selector(didTapSize(_:)))
            button.tag = index
            sizeButtons[size] = button
            views.append(button)
        }
        views.append(makeSeparator())
        for (symbol, tip, action) in [
            ("doc.on.clipboard", "Copy (Enter)", #selector(didTapCopy)),
            ("square.and.arrow.down", "Save (⌘S)", #selector(didTapSave)),
            ("xmark", "Cancel (Esc)", #selector(didTapCancel)),
        ] as [(String, String, Selector)] {
            views.append(
                makeButton(
                    image: NSImage(systemSymbolName: symbol, accessibilityDescription: tip) ?? NSImage(), tip: tip,
                    side: Self.button, action: action))
        }

        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.distribution = .fill
        stack.alignment = .centerY
        stack.spacing = Self.spacing
        stack.edgeInsets = NSEdgeInsets(top: 4, left: Self.inset, bottom: 4, right: Self.inset)
        stack.frame = bounds
        stack.autoresizingMask = [.width, .height]
        addSubview(stack)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("OverlayToolbar is created in code only") }

    // Presses on the toolbar's padding or gaps must not reach the overlay view underneath, which
    // would treat them as a new selection. Right-clicks are left alone so they still cancel.
    override func mouseDown(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    func setTool(_ tool: AnnotationTool) {
        self.tool = tool
        refresh()
    }

    func setColor(_ color: AnnotationColor) {
        self.color = color
        refresh()
    }

    func setSize(_ size: AnnotationSize) {
        self.size = size
        refresh()
    }

    private func refresh() {
        for (tool, button) in toolButtons {
            button.wantsLayer = true
            button.layer?.cornerRadius = 5
            button.layer?.backgroundColor =
                tool == self.tool ? NSColor.white.withAlphaComponent(0.28).cgColor : nil
        }
        for (color, button) in colorButtons {
            button.image = Self.swatchImage(color: color, selected: color == self.color)
        }
        for (size, button) in sizeButtons {
            button.image = Self.dotImage(size: size)
            button.wantsLayer = true
            button.layer?.cornerRadius = 5
            button.layer?.backgroundColor =
                size == self.size ? NSColor.white.withAlphaComponent(0.28).cgColor : nil
        }
    }

    private func makeButton(image: NSImage, tip: String, side: CGFloat, action: Selector) -> NSButton {
        let button = NSButton(image: image, target: self, action: action)
        button.isBordered = false
        button.contentTintColor = .white
        button.imagePosition = .imageOnly
        button.toolTip = tip
        button.refusesFirstResponder = true  // keep keyboard focus on the overlay view
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: side).isActive = true
        button.heightAnchor.constraint(equalToConstant: side).isActive = true
        return button
    }

    private func makeSeparator() -> NSView {
        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.25).cgColor
        line.translatesAutoresizingMaskIntoConstraints = false
        line.widthAnchor.constraint(equalToConstant: 1).isActive = true
        line.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return line
    }

    private static func swatchImage(color: AnnotationColor, selected: Bool) -> NSImage {
        NSImage(size: NSSize(width: swatch, height: swatch), flipped: false) { rect in
            color.nsColor.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3)).fill()
            if selected {
                NSColor.white.setStroke()
                let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
                ring.lineWidth = 1.5
                ring.stroke()
            }
            return true
        }
    }

    private static func dotImage(size: AnnotationSize) -> NSImage {
        let diameter: CGFloat = size == .small ? 5 : size == .medium ? 9 : 13
        return NSImage(size: NSSize(width: button, height: button), flipped: false) { rect in
            NSColor.white.setFill()
            NSBezierPath(
                ovalIn: CGRect(
                    x: rect.midX - diameter / 2, y: rect.midY - diameter / 2, width: diameter, height: diameter)
            ).fill()
            return true
        }
    }

    @objc private func didTapTool(_ sender: NSButton) { onTool?(AnnotationTool.allCases[sender.tag]) }
    @objc private func didTapColor(_ sender: NSButton) { onColor?(AnnotationColor.allCases[sender.tag]) }
    @objc private func didTapSize(_ sender: NSButton) { onSize?(AnnotationSize.allCases[sender.tag]) }
    @objc private func didTapCopy() { onCopy?() }
    @objc private func didTapSave() { onSave?() }
    @objc private func didTapCancel() { onCancel?() }
}
