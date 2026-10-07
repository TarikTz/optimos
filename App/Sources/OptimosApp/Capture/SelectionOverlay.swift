import AppKit

enum SelectionMode {
    case area
    case window
}

/// A borderless window that covers one display.
@MainActor
final class OverlayWindow: NSWindow {
    init(screen: NSScreen, contentView: NSView) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        self.contentView = contentView
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
        setFrame(screen.frame, display: false)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Draws one display's frozen image, dimmed, and handles the mouse and keyboard on it.
/// The view is flipped so its coordinates are display-local points with a top-left origin,
/// matching `CaptureSelection` and the pixel layout of the frozen image.
@MainActor
final class SelectionView: NSView {
    var mode: SelectionMode = .area {
        didSet {
            dragStart = nil
            dragRect = nil
            hoveredWindowRect = nil
            discardConfirmation()
            updateHover()
            needsDisplay = true
        }
    }
    var onFinish: ((OverlayOutcome?) -> Void)?
    var onToggleMode: (() -> Void)?
    /// A selection was confirmed (the toolbar is showing).
    var onConfirm: (() -> Void)?
    /// A new press began; the controller clears any confirmation on every display.
    var onBeginSelection: (() -> Void)?
    /// The pointer entered this display; the controller decides whether this window takes key status.
    var onPointerEntered: (() -> Void)?

    private let display: FrozenDisplay
    private let windows: [WindowInfo]
    private let background: NSImage
    private var dragStart: CGPoint?
    private var dragRect: CGRect?
    private var hoveredWindowRect: CGRect?
    /// The mode the current mouse press started in; nil when no button is down. Kept across a
    /// Space toggle so a press that began in one mode can never finish as a capture in the other.
    private var pressMode: SelectionMode?
    /// The selection fixed on release; while set, the toolbar is showing and Copy/Save/Cancel apply to it.
    private var confirmedRect: CGRect?
    private var toolbar: OverlayToolbar?
    /// The toolbar's output choices for the current capture; they start from the saved defaults every time.
    private let outputDefaults: OutputChoice
    private var output: OutputChoice

    // Annotation state for the confirmed selection.
    private var document = AnnotationDocument()
    private var tool: AnnotationTool = .select
    private var color: AnnotationColor = .red
    private var size: AnnotationSize = .medium
    /// Where the current draw drag started, and the shape it is producing.
    private var drawStart: CGPoint?
    private var draftShape: Annotation?
    /// The last point of the current move drag.
    private var moveLast: CGPoint?
    /// A drag of the selection itself: a handle (resize) or its inside (move).
    private enum SelectionDrag {
        case resize(ResizeHandle)
        case move(grabOffset: CGSize)
    }
    private var selectionDrag: SelectionDrag?
    /// A drag of one handle of the selected annotation.
    private var annotationHandleDrag: ResizeHandle?
    /// Text being typed inline; it becomes an annotation when finished.
    private var textDraft: (origin: CGPoint, string: String)?

    init(display: FrozenDisplay, windows: [WindowInfo], outputDefaults: OutputChoice) {
        self.display = display
        self.outputDefaults = outputDefaults
        self.output = outputDefaults
        self.windows = windows
        self.background = NSImage(cgImage: display.image, size: display.info.frame.size)
        super.init(frame: NSRect(origin: .zero, size: display.info.frame.size))
    }

    required init?(coder: NSCoder) { fatalError("SelectionView is created in code only") }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: Mouse

    override func mouseEntered(with event: NSEvent) {
        onPointerEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        hoveredWindowRect = nil
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover()
    }

    override func mouseDown(with event: NSEvent) {
        if let rect = confirmedRect, handleAnnotationPress(at: convert(event.locationInWindow, from: nil), in: rect) {
            return
        }
        // Pressing outside the toolbar starts over: any confirmed selection (on any display) is dropped.
        onBeginSelection?()
        // The pointer may be on a display whose window never took key status while another display
        // held a confirmed selection; starting a selection here makes this window key again.
        window?.makeKeyAndOrderFront(nil)
        pressMode = mode
        guard mode == .area else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        dragRect = CGRect(origin: point, size: .zero)
    }

    override func mouseDragged(with event: NSEvent) {
        if let rect = confirmedRect, drawStart != nil || moveLast != nil || selectionDrag != nil || annotationHandleDrag != nil {
            dragAnnotation(to: convert(event.locationInWindow, from: nil), in: rect)
            return
        }
        if mode == .window {
            // Press-drag-release in window mode captures the window under the cursor at release,
            // so keep the highlight following the cursor while the button is down.
            updateHover()
            return
        }
        guard mode == .area, let start = dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragRect = CaptureGeometry.normalizedRect(from: start, to: point).intersection(bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if drawStart != nil || moveLast != nil || selectionDrag != nil || annotationHandleDrag != nil {
            finishAnnotationDrag()
            return
        }
        let pressMode = self.pressMode
        self.pressMode = nil
        switch mode {
        case .area:
            let rect = dragRect
            dragStart = nil
            dragRect = nil
            needsDisplay = true
            guard let rect, CaptureGeometry.isAcceptable(rect) else { return }
            confirm(rect)
        case .window:
            guard let rect = CaptureGeometry.windowCaptureRect(
                pressMode: pressMode, currentMode: mode, hoveredRect: hoveredWindowRect)
            else { return }
            confirm(rect)
        }
    }

    // MARK: Confirm toolbar

    /// Fixes the selection and shows the Copy / Save / Cancel toolbar next to it.
    private func confirm(_ rect: CGRect) {
        confirmedRect = rect
        document = AnnotationDocument()
        tool = .select
        output = outputDefaults
        let bar = OverlayToolbar(tool: tool, color: color, size: size, output: output)
        bar.onFormat = { [weak self] in self?.output.format = $0 }
        bar.onMaxSide = { [weak self] in self?.output.maxSide = $0 }
        bar.onShare = { [weak self] in self?.finish(with: .share) }
        bar.onTool = { [weak self] in self?.setTool($0) }
        bar.onColor = { [weak self] in self?.setColor($0) }
        bar.onSize = { [weak self] in self?.setSize($0) }
        bar.onCopy = { [weak self] in self?.finish(with: .copy) }
        bar.onSave = { [weak self] in self?.finish(with: .save) }
        bar.onCancel = { [weak self] in self?.onFinish?(nil) }
        bar.frame = ToolbarPlacement.frame(
            for: rect, toolbarSize: OverlayToolbar.size, displaySize: bounds.size)
        addSubview(bar)
        toolbar = bar
        needsDisplay = true
        // Enter/⌘C/⌘S must reach this view wherever the pointer goes next.
        window?.makeKeyAndOrderFront(nil)
        onConfirm?()
    }

    /// Drops a confirmed selection and its toolbar (also called by the controller for other displays).
    func discardConfirmation() {
        guard confirmedRect != nil else { return }
        confirmedRect = nil
        document = AnnotationDocument()
        drawStart = nil
        draftShape = nil
        moveLast = nil
        selectionDrag = nil
        annotationHandleDrag = nil
        textDraft = nil
        toolbar?.removeFromSuperview()
        toolbar = nil
        updateHover()
        needsDisplay = true
    }

    private func finish(with action: CaptureAction) {
        guard let rect = confirmedRect else { return }
        commitText()
        onFinish?(OverlayOutcome(
            selection: CaptureSelection(displayID: display.info.id, rect: rect), action: action,
            annotations: document.annotations, output: output, toolbarFrame: toolbar?.frame ?? .zero))
    }

    // MARK: Annotations

    /// Handles a press while a selection is confirmed. Returns false when the press should instead
    /// start a new selection (only when no annotation work would be lost).
    private func handleAnnotationPress(at point: CGPoint, in rect: CGRect) -> Bool {
        commitText()
        // Handles come first: the selected annotation's (Select tool), then the selection's own.
        if tool == .select, let selected = document.selected,
            let handle = HandleGeometry.handle(at: point, in: selected.handlePositions)
        {
            document.beginMove()
            annotationHandleDrag = handle
            return true
        }
        if let handle = HandleGeometry.handle(at: point, in: HandleGeometry.positions(for: rect)) {
            selectionDrag = .resize(handle)
            return true
        }
        guard rect.contains(point) else { return !document.isEmpty }
        switch tool {
        case .select:
            if let hit = AnnotationHitTesting.annotation(at: point, in: document.annotations) {
                document.select(hit.id)
                document.beginMove()
                moveLast = point
            } else {
                // Empty space inside the selection: a click deselects, a drag moves the selection.
                document.select(nil)
                selectionDrag = .move(grabOffset: CGSize(width: point.x - rect.minX, height: point.y - rect.minY))
            }
        case .rectangle, .arrow, .pixelate:
            document.select(nil)
            drawStart = point
            draftShape = shape(from: point, to: point)
        case .text:
            document.select(nil)
            textDraft = (point, "")
        }
        needsDisplay = true
        return true
    }

    private func shape(from start: CGPoint, to end: CGPoint) -> Annotation? {
        let kind: AnnotationKind
        switch tool {
        case .rectangle: kind = .rectangle(CaptureGeometry.normalizedRect(from: start, to: end))
        case .pixelate: kind = .pixelate(CaptureGeometry.normalizedRect(from: start, to: end))
        case .arrow: kind = .arrow(from: start, to: end)
        case .select, .text: return nil
        }
        return Annotation(kind: kind, color: color, size: size)
    }

    private func dragAnnotation(to point: CGPoint, in rect: CGRect) {
        if let drag = selectionDrag {
            switch drag {
            case .resize(let handle):
                confirmedRect = HandleGeometry.resized(rect, dragging: handle, to: point, minSize: 4, within: bounds)
            case .move(let offset):
                let x = min(max(point.x - offset.width, bounds.minX), bounds.maxX - rect.width)
                let y = min(max(point.y - offset.height, bounds.minY), bounds.maxY - rect.height)
                confirmedRect = CGRect(x: x, y: y, width: rect.width, height: rect.height)
            }
            toolbar?.frame = ToolbarPlacement.frame(
                for: confirmedRect ?? rect, toolbarSize: OverlayToolbar.size, displaySize: bounds.size)
        } else if let handle = annotationHandleDrag {
            document.resizeSelected(handle, to: point, within: rect)
        } else if let last = moveLast {
            document.moveSelected(by: CGSize(width: point.x - last.x, height: point.y - last.y))
            moveLast = point
        } else if let start = drawStart {
            let clamped = CGPoint(
                x: min(max(point.x, rect.minX), rect.maxX), y: min(max(point.y, rect.minY), rect.maxY))
            draftShape = shape(from: start, to: clamped)
        }
        needsDisplay = true
    }

    private func finishAnnotationDrag() {
        defer {
            drawStart = nil
            draftShape = nil
            moveLast = nil
            selectionDrag = nil
            annotationHandleDrag = nil
            pressMode = nil
            needsDisplay = true
        }
        guard let shape = draftShape else { return }
        let big: Bool
        switch shape.kind {
        case .rectangle(let rect), .pixelate(let rect): big = rect.width >= 3 && rect.height >= 3
        case .arrow(let from, let to): big = hypot(to.x - from.x, to.y - from.y) >= 6
        case .text: big = false
        }
        if big { document.add(shape) }
    }

    private func commitText() {
        guard let draft = textDraft else { return }
        textDraft = nil
        needsDisplay = true
        guard !draft.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        document.add(Annotation(kind: .text(origin: draft.origin, string: draft.string), color: color, size: size))
    }

    private func setTool(_ newTool: AnnotationTool) {
        commitText()
        tool = newTool
        toolbar?.setTool(newTool)
        needsDisplay = true
    }

    private func setColor(_ newColor: AnnotationColor) {
        color = newColor
        document.setColorOfSelected(newColor)
        toolbar?.setColor(newColor)
        needsDisplay = true
    }

    private func setSize(_ newSize: AnnotationSize) {
        size = newSize
        document.setSizeOfSelected(newSize)
        toolbar?.setSize(newSize)
        needsDisplay = true
    }

    /// Typing into the inline text box. Returns true when the key was consumed.
    private func handleTextKey(_ event: NSEvent) -> Bool {
        guard var draft = textDraft else { return false }
        if event.modifierFlags.contains(.command) { return false }
        switch event.keyCode {
        case 53:  // Esc finishes the text; a second Esc cancels the overlay
            commitText()
            return true
        case 51:
            _ = draft.string.popLast()
        case 36, 76:
            draft.string.append("\n")
        default:
            // Printable characters only: arrows and other function keys arrive as private-use scalars.
            let typed = (event.characters ?? "").unicodeScalars.filter {
                $0.value >= 0x20 && $0.value != 0x7F && !(0xF700...0xF8FF).contains($0.value)
            }
            draft.string.unicodeScalars.append(contentsOf: typed)
        }
        textDraft = draft
        needsDisplay = true
        return true
    }

    override func rightMouseDown(with event: NSEvent) {
        onFinish?(nil)
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        if textDraft != nil, handleTextKey(event) { return }
        if handle(event) { return }
        if event.keyCode == 49 {  // Space: toggles area/window; ignored while a selection is confirmed
            if !event.isARepeat && confirmedRect == nil { onToggleMode?() }
            return
        }
        super.keyDown(with: event)
    }

    /// ⌘C and ⌘S arrive as key equivalents, before `keyDown`.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return false }
        return handle(event)
    }

    private func handle(_ event: NSEvent) -> Bool {
        guard
            let action = OverlayKeyAction.from(
                keyCode: event.keyCode, modifiers: event.modifierFlags, isRepeat: event.isARepeat)
        else { return false }
        switch action {
        case .cancel:
            onFinish?(nil)
            return true
        case .copy, .save:
            guard confirmedRect != nil else { return false }  // nothing to confirm yet
            finish(with: action == .copy ? .copy : .save)
            return true
        case .undo, .redo, .deleteSelected, .tool:
            guard confirmedRect != nil else { return false }
            // While typing text, history keys are swallowed so they cannot undo the previous step.
            if textDraft != nil { return true }
            switch action {
            case .undo: document.undo()
            case .redo: document.redo()
            case .deleteSelected: document.deleteSelected()
            case .tool(let newTool): setTool(newTool)
            default: break
            }
            needsDisplay = true
            return true
        }
    }

    // MARK: Window hover

    private func currentMouse() -> CGPoint? {
        guard let window else { return nil }
        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return bounds.contains(point) ? point : nil
    }

    private func updateHover() {
        guard mode == .window, confirmedRect == nil, let point = currentMouse() else {
            if hoveredWindowRect != nil {
                hoveredWindowRect = nil
                needsDisplay = true
            }
            return
        }
        let rect = CaptureGeometry.topmostWindow(at: point, in: windows, display: display.info)
            .flatMap { CaptureGeometry.localRect(of: $0, on: display.info) }
        if rect != hoveredWindowRect {
            hoveredWindowRect = rect
            needsDisplay = true
        }
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        background.draw(
            in: bounds, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)

        let highlight = (confirmedRect ?? (mode == .area ? dragRect : hoveredWindowRect)).flatMap {
            $0.width > 0 && $0.height > 0 ? $0 : nil
        }

        let dim = NSBezierPath(rect: bounds)
        if let highlight {
            dim.append(NSBezierPath(rect: highlight))
            dim.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.4).setFill()
        dim.fill()

        drawAnnotations()

        guard let highlight else { return }
        let border = NSBezierPath(rect: highlight)
        border.lineWidth = mode == .window ? 3 : 1
        (mode == .window ? NSColor.controlAccentColor : NSColor.white).setStroke()
        border.stroke()
        drawSizeLabel(for: highlight)
        if confirmedRect != nil, let ctx = NSGraphicsContext.current?.cgContext { drawHandles(in: ctx, rect: highlight) }
    }

    private func drawAnnotations() {
        guard let rect = confirmedRect, let ctx = NSGraphicsContext.current?.cgContext else { return }
        var items = document.annotations
        if let draftShape { items.append(draftShape) }
        if let textDraft {
            items.append(
                Annotation(kind: .text(origin: textDraft.origin, string: textDraft.string + "|"), color: color, size: size))
        }
        ctx.saveGState()
        ctx.clip(to: rect)
        AnnotationRenderer.draw(
            items, in: ctx, source: display.image, pointScale: CGFloat(display.image.width) / bounds.width)
        if let selected = document.selected {
            ctx.setStrokeColor(NSColor.controlAccentColor.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineDash(phase: 0, lengths: [4, 3])
            ctx.stroke(selected.bounds.insetBy(dx: -4, dy: -4))
        }
        ctx.restoreGState()
    }

    /// Small squares on the selection's border (always) and on the selected annotation (Select tool).
    private func drawHandles(in ctx: CGContext, rect: CGRect) {
        func square(at point: CGPoint, fill: NSColor, size: CGFloat) {
            let r = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
            ctx.setFillColor(fill.cgColor)
            ctx.fill(r)
            ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.55).cgColor)
            ctx.setLineWidth(1)
            ctx.stroke(r)
        }
        if tool == .select, let selected = document.selected {
            for (_, point) in selected.handlePositions { square(at: point, fill: .controlAccentColor, size: 8) }
        }
        for (_, point) in HandleGeometry.positions(for: rect) { square(at: point, fill: .white, size: 8) }
    }

    private func drawSizeLabel(for rect: CGRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = text.size(withAttributes: attributes)
        var y = rect.minY - size.height - 10
        if y < 2 { y = rect.minY + 6 }
        let pill = CGRect(x: max(2, rect.minX), y: y, width: size.width + 12, height: size.height + 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: pill, xRadius: 4, yRadius: 4).fill()
        text.draw(at: CGPoint(x: pill.minX + 6, y: pill.minY + 2), withAttributes: attributes)
    }
}

/// Shows an overlay on every display and returns the confirmed selection with the chosen action,
/// or nil if cancelled.
@MainActor
final class SelectionOverlayController {
    private var overlayWindows: [OverlayWindow] = []
    private var views: [SelectionView] = []
    private var continuation: CheckedContinuation<OverlayOutcome?, Never>?
    /// True while a selection is confirmed (toolbar showing); Space is ignored then.
    private var isConfirming = false
    private var resignObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?
    private var previousApp: NSRunningApplication?
    private var mode: SelectionMode = .area {
        didSet { views.forEach { $0.mode = mode } }
    }

    var isActive: Bool { continuation != nil }

    func run(displays: [FrozenDisplay], windows: [WindowInfo], outputDefaults: OutputChoice) async -> OverlayOutcome? {
        guard continuation == nil else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            present(displays: displays, windows: windows, outputDefaults: outputDefaults)
        }
    }

    func cancel() {
        finish(nil)
    }

    private func present(displays: [FrozenDisplay], windows: [WindowInfo], outputDefaults: OutputChoice) {
        mode = .area
        for display in displays {
            guard let screen = NSScreen.screens.first(where: { $0.displayID == display.info.id }) else { continue }
            let view = SelectionView(display: display, windows: windows, outputDefaults: outputDefaults)
            view.onFinish = { [weak self] outcome in self?.finish(outcome) }
            view.onToggleMode = { [weak self] in self?.toggleMode() }
            view.onConfirm = { [weak self, weak view] in self?.selectionConfirmed(on: view) }
            view.onBeginSelection = { [weak self] in self?.beginSelection() }
            // While a selection is confirmed the key window stays put, so the confirm keys keep
            // reaching the confirmed view even when the pointer moves to another display.
            view.onPointerEntered = { [weak self, weak view] in
                if self?.isConfirming == false { view?.window?.makeKeyAndOrderFront(nil) }
            }
            views.append(view)
            overlayWindows.append(OverlayWindow(screen: screen, contentView: view))
        }
        guard !overlayWindows.isEmpty else {
            finish(nil)
            return
        }

        // Remember who had focus; an accessory app with no windows would otherwise stay frontmost
        // after the overlay closes and swallow the user's typing.
        if let front = NSWorkspace.shared.frontmostApplication,
            front.processIdentifier != ProcessInfo.processInfo.processIdentifier
        {
            previousApp = front
        }

        // Safety net: if the user switches away (Cmd-Tab, Mission Control), never leave a stuck overlay.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish(nil, restoreFocus: false) }
        }

        // Mission Control / Space switches do not resign app activation, and the overlay is
        // .stationary at screen-saver level, so it would stay drawn without this observer.
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish(nil, restoreFocus: false) }
        }

        NSApp.activate(ignoringOtherApps: true)
        // Make the view first responder so Esc works before the first click.
        for window in overlayWindows { window.makeFirstResponder(window.contentView) }
        overlayWindows.forEach { $0.orderFrontRegardless() }
        let mouse = NSEvent.mouseLocation
        (overlayWindows.first { NSMouseInRect(mouse, $0.frame, false) } ?? overlayWindows[0])
            .makeKeyAndOrderFront(nil)
    }

    private func toggleMode() {
        guard !isConfirming else { return }
        mode = mode == .area ? .window : .area
    }

    /// One display confirmed a selection: no other display may keep one.
    private func selectionConfirmed(on confirmedView: SelectionView?) {
        isConfirming = true
        for view in views where view !== confirmedView { view.discardConfirmation() }
    }

    /// A new press began somewhere: drop every confirmation and allow mode changes again.
    private func beginSelection() {
        isConfirming = false
        views.forEach { $0.discardConfirmation() }
    }

    private func finish(_ outcome: OverlayOutcome?, restoreFocus: Bool = true) {
        guard let continuation else { return }
        self.continuation = nil
        isConfirming = false
        // Remove observers first so reactivating the previous app below cannot re-trigger cancel.
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        if let spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver) }
        resignObserver = nil
        spaceObserver = nil
        overlayWindows.forEach { $0.orderOut(nil) }
        // finish() can run inside a window's own mouseUp/rightMouseDown; keep the windows alive one
        // more run-loop turn so the dispatching window is never deallocated mid-event.
        let windowsToRelease = overlayWindows
        let viewsToRelease = views
        overlayWindows = []
        views = []
        DispatchQueue.main.async { _ = (windowsToRelease, viewsToRelease) }
        // Give keyboard focus back only for exits that start inside the overlay. Observer-driven
        // cancels (app switch, Space change) mean the user already moved on; reactivating the old
        // app could pull them back to the Space they just left. NSApp.isActive guards the rest.
        if restoreFocus, NSApp.isActive {
            previousApp?.activate(from: NSRunningApplication.current, options: [])
        }
        previousApp = nil
        continuation.resume(returning: outcome)
    }
}
