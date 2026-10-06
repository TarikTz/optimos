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
            updateHover()
            needsDisplay = true
        }
    }
    var onFinish: ((CaptureSelection?) -> Void)?
    var onToggleMode: (() -> Void)?

    private let display: FrozenDisplay
    private let windows: [WindowInfo]
    private let background: NSImage
    private var dragStart: CGPoint?
    private var dragRect: CGRect?
    private var hoveredWindowRect: CGRect?

    init(display: FrozenDisplay, windows: [WindowInfo]) {
        self.display = display
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
        window?.makeKeyAndOrderFront(nil)
    }

    override func mouseExited(with event: NSEvent) {
        hoveredWindowRect = nil
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover()
    }

    override func mouseDown(with event: NSEvent) {
        guard mode == .area else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        dragRect = CGRect(origin: point, size: .zero)
    }

    override func mouseDragged(with event: NSEvent) {
        guard mode == .area, let start = dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragRect = CaptureGeometry.normalizedRect(from: start, to: point).intersection(bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        switch mode {
        case .area:
            let rect = dragRect
            dragStart = nil
            dragRect = nil
            needsDisplay = true
            guard let rect, CaptureGeometry.isAcceptable(rect) else { return }
            onFinish?(CaptureSelection(displayID: display.info.id, rect: rect))
        case .window:
            guard let rect = hoveredWindowRect else { return }
            onFinish?(CaptureSelection(displayID: display.info.id, rect: rect))
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onFinish?(nil)
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: onFinish?(nil)  // Esc
        case 49: onToggleMode?()  // Space
        default: super.keyDown(with: event)
        }
    }

    // MARK: Window hover

    private func currentMouse() -> CGPoint? {
        guard let window else { return nil }
        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return bounds.contains(point) ? point : nil
    }

    private func updateHover() {
        guard mode == .window, let point = currentMouse() else {
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

        let highlight = (mode == .area ? dragRect : hoveredWindowRect).flatMap {
            $0.width > 0 && $0.height > 0 ? $0 : nil
        }

        let dim = NSBezierPath(rect: bounds)
        if let highlight {
            dim.append(NSBezierPath(rect: highlight))
            dim.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.4).setFill()
        dim.fill()

        guard let highlight else { return }
        let border = NSBezierPath(rect: highlight)
        border.lineWidth = mode == .window ? 3 : 1
        (mode == .window ? NSColor.controlAccentColor : NSColor.white).setStroke()
        border.stroke()
        drawSizeLabel(for: highlight)
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

/// Shows an overlay on every display and returns what the user picked, or nil if cancelled.
@MainActor
final class SelectionOverlayController {
    private var overlayWindows: [OverlayWindow] = []
    private var views: [SelectionView] = []
    private var continuation: CheckedContinuation<CaptureSelection?, Never>?
    private var resignObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?
    private var previousApp: NSRunningApplication?
    private var mode: SelectionMode = .area {
        didSet { views.forEach { $0.mode = mode } }
    }

    var isActive: Bool { continuation != nil }

    func run(displays: [FrozenDisplay], windows: [WindowInfo]) async -> CaptureSelection? {
        guard continuation == nil else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            present(displays: displays, windows: windows)
        }
    }

    func cancel() {
        finish(nil)
    }

    private func present(displays: [FrozenDisplay], windows: [WindowInfo]) {
        mode = .area
        for display in displays {
            guard let screen = NSScreen.screens.first(where: { $0.displayID == display.info.id }) else { continue }
            let view = SelectionView(display: display, windows: windows)
            view.onFinish = { [weak self] selection in self?.finish(selection) }
            view.onToggleMode = { [weak self] in self?.toggleMode() }
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
        mode = mode == .area ? .window : .area
    }

    private func finish(_ selection: CaptureSelection?, restoreFocus: Bool = true) {
        guard let continuation else { return }
        self.continuation = nil
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
        continuation.resume(returning: selection)
    }
}
