import AppKit
import OptimosCore

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
    private static let separators = 2
    private static let rowHeight: CGFloat = 36

    /// Two rows: annotation controls on top, output controls below. The width comes from the same
    /// constants that lay the top row out, so placement always knows the real size.
    static let size: CGSize = {
        let buttons = CGFloat(toolCount + sizeCount) * button
        let swatches = CGFloat(swatchCount) * swatch
        let elements = toolCount + swatchCount + sizeCount + separators
        return CGSize(
            width: buttons + swatches + CGFloat(separators) + CGFloat(elements - 1) * spacing + 2 * inset,
            height: rowHeight * 2)
    }()

    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onTool: ((AnnotationTool) -> Void)?
    var onColor: ((AnnotationColor) -> Void)?
    var onSize: ((AnnotationSize) -> Void)?
    var onShare: (() -> Void)?
    var onFormat: ((ImageFormat) -> Void)?
    var onMaxSide: ((Int?) -> Void)?

    private var toolButtons: [AnnotationTool: NSButton] = [:]
    private var colorButtons: [AnnotationColor: NSButton] = [:]
    private var sizeButtons: [AnnotationSize: NSButton] = [:]
    private let formatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let sizePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private static let maxSides: [Int?] = [nil, 3840, 2560, 1920, 1280, 800]
    private static let formats: [ImageFormat] = [.png, .jpeg, .webp]
    private var tool: AnnotationTool
    private var color: AnnotationColor
    private var size: AnnotationSize

    init(
        tool: AnnotationTool = .select, color: AnnotationColor = .red, size: AnnotationSize = .medium,
        output: OutputChoice = OutputChoice(format: .png, maxSide: nil)
    ) {
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
        let top = NSStackView(views: views)
        top.orientation = .horizontal
        top.distribution = .fill
        top.alignment = .centerY
        top.spacing = Self.spacing

        // Output row: format and max size on the left, Share / Copy / Save / Cancel on the right.
        for format in Self.formats { formatPopup.addItem(withTitle: format == .jpeg ? "JPEG" : format.rawValue.uppercased()) }
        formatPopup.selectItem(at: Self.formats.firstIndex(of: output.format) ?? 0)
        formatPopup.target = self
        formatPopup.action = #selector(didPickFormat)
        for side in Self.maxSides { sizePopup.addItem(withTitle: side.map { "Fit \($0) px" } ?? "Original size") }
        sizePopup.selectItem(at: Self.maxSides.firstIndex(where: { $0 == output.maxSide }) ?? 0)
        sizePopup.target = self
        sizePopup.action = #selector(didPickSize)
        for popup in [formatPopup, sizePopup] {
            popup.controlSize = .small
            popup.refusesFirstResponder = true  // keep keyboard focus on the overlay view
            popup.appearance = NSAppearance(named: .darkAqua)
        }
        var bottomViews: [NSView] = [formatPopup, sizePopup]
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bottomViews.append(spacer)
        for (symbol, tip, action) in [
            ("square.and.arrow.up", "Share…", #selector(didTapShare)),
            ("doc.on.clipboard", "Copy (Enter)", #selector(didTapCopy)),
            ("square.and.arrow.down", "Save (⌘S)", #selector(didTapSave)),
            ("xmark", "Cancel (Esc)", #selector(didTapCancel)),
        ] as [(String, String, Selector)] {
            bottomViews.append(
                makeButton(
                    image: NSImage(systemSymbolName: symbol, accessibilityDescription: tip) ?? NSImage(), tip: tip,
                    side: Self.button, action: action))
        }
        let bottom = NSStackView(views: bottomViews)
        bottom.orientation = .horizontal
        bottom.distribution = .fill
        bottom.alignment = .centerY
        bottom.spacing = Self.spacing

        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let rows = NSStackView(views: [top, divider, bottom])
        rows.orientation = .vertical
        rows.distribution = .fill
        rows.alignment = .leading
        rows.spacing = 5
        rows.edgeInsets = NSEdgeInsets(top: 6, left: Self.inset, bottom: 6, right: Self.inset)
        rows.frame = bounds
        rows.autoresizingMask = [.width, .height]
        for row in [top, divider, bottom] { row.widthAnchor.constraint(equalTo: rows.widthAnchor, constant: -2 * Self.inset).isActive = true }
        addSubview(rows)
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

    func setFormat(_ format: ImageFormat) {
        formatPopup.selectItem(at: Self.formats.firstIndex(of: format) ?? 0)
    }

    func setMaxSide(_ side: Int?) {
        sizePopup.selectItem(at: Self.maxSides.firstIndex(where: { $0 == side }) ?? 0)
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
    @objc private func didTapShare() { onShare?() }
    @objc private func didPickFormat() { onFormat?(Self.formats[max(0, formatPopup.indexOfSelectedItem)]) }
    @objc private func didPickSize() { onMaxSide?(Self.maxSides[max(0, sizePopup.indexOfSelectedItem)]) }
    @objc private func didTapCopy() { onCopy?() }
    @objc private func didTapSave() { onSave?() }
    @objc private func didTapCancel() { onCancel?() }
}
