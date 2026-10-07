import AppKit

/// Annotation editing for the capture overlay: drawing and moving shapes, handle drags, inline text,
/// and drawing the annotations and handles. The state lives in `SelectionView`; this file holds the logic.
extension SelectionView {
    // MARK: Annotations

    /// Handles a press while a selection is confirmed. Returns false when the press should instead
    /// start a new selection (only when no annotation work would be lost).
    func handleAnnotationPress(at point: CGPoint, in rect: CGRect) -> Bool {
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
        case .rectangle, .ellipse, .arrow, .line, .highlight, .pixelate, .blur:
            document.select(nil)
            drawStart = point
            draftShape = shape(from: point, to: point)
        case .marker:
            // One click places the next number.
            document.add(Annotation(kind: .marker(center: point, number: document.nextMarkerNumber), color: color, size: size))
        case .text:
            document.select(nil)
            textDraft = (point, "")
        }
        needsDisplay = true
        return true
    }

    func shape(from start: CGPoint, to end: CGPoint) -> Annotation? {
        let kind: AnnotationKind
        switch tool {
        case .rectangle: kind = .rectangle(CaptureGeometry.normalizedRect(from: start, to: end))
        case .ellipse: kind = .ellipse(CaptureGeometry.normalizedRect(from: start, to: end))
        case .highlight: kind = .highlight(CaptureGeometry.normalizedRect(from: start, to: end))
        case .pixelate: kind = .pixelate(CaptureGeometry.normalizedRect(from: start, to: end))
        case .blur: kind = .blur(CaptureGeometry.normalizedRect(from: start, to: end))
        case .arrow: kind = .arrow(from: start, to: end)
        case .line: kind = .line(from: start, to: end)
        case .select, .text, .marker: return nil
        }
        return Annotation(kind: kind, color: color, size: size)
    }

    func dragAnnotation(to point: CGPoint, in rect: CGRect) {
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

    func finishAnnotationDrag() {
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
        case .rectangle(let rect), .ellipse(let rect), .highlight(let rect), .pixelate(let rect), .blur(let rect):
            big = rect.width >= 3 && rect.height >= 3
        case .arrow(let from, let to), .line(let from, let to): big = hypot(to.x - from.x, to.y - from.y) >= 6
        case .text, .marker: big = false
        }
        if big { document.add(shape) }
    }

    func commitText() {
        guard let draft = textDraft else { return }
        textDraft = nil
        needsDisplay = true
        guard !draft.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        document.add(Annotation(kind: .text(origin: draft.origin, string: draft.string), color: color, size: size))
    }

    func setTool(_ newTool: AnnotationTool) {
        commitText()
        tool = newTool
        toolbar?.setTool(newTool)
        needsDisplay = true
    }

    func setColor(_ newColor: AnnotationColor) {
        color = newColor
        document.setColorOfSelected(newColor)
        toolbar?.setColor(newColor)
        needsDisplay = true
    }

    func setSize(_ newSize: AnnotationSize) {
        size = newSize
        document.setSizeOfSelected(newSize)
        toolbar?.setSize(newSize)
        needsDisplay = true
    }

    /// Typing into the inline text box. Returns true when the key was consumed.
    func handleTextKey(_ event: NSEvent) -> Bool {
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

    func drawAnnotations() {
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
    func drawHandles(in ctx: CGContext, rect: CGRect) {
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
}
