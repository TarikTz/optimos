import CoreGraphics
import Foundation

/// The annotations on one confirmed selection, the selected one, and the undo/redo history.
/// Every add, delete, recolour, resize and whole drag-move is one undoable step; selection is not.
struct AnnotationDocument {
    private(set) var annotations: [Annotation] = []
    private(set) var selectedID: UUID?
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private var moveStepOpen = false

    var isEmpty: Bool { annotations.isEmpty }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var selected: Annotation? { annotations.first { $0.id == selectedID } }

    mutating func select(_ id: UUID?) {
        selectedID = id.flatMap { id in annotations.contains { $0.id == id } ? id : nil }
    }

    mutating func add(_ annotation: Annotation) {
        checkpoint()
        annotations.append(annotation)
        selectedID = annotation.id
    }

    mutating func deleteSelected() {
        guard let selectedID, annotations.contains(where: { $0.id == selectedID }) else { return }
        checkpoint()
        annotations.removeAll { $0.id == selectedID }
        self.selectedID = nil
    }

    mutating func setColorOfSelected(_ color: AnnotationColor) {
        guard let index = selectedIndex, annotations[index].color != color else { return }
        checkpoint()
        annotations[index].color = color
    }

    mutating func setSizeOfSelected(_ size: AnnotationSize) {
        guard let index = selectedIndex, annotations[index].size != size else { return }
        checkpoint()
        annotations[index].size = size
    }

    /// Call when a drag-move begins; the first `moveSelected` after it records one undo step.
    mutating func beginMove() {
        moveStepOpen = false
    }

    mutating func moveSelected(by delta: CGSize) {
        guard let index = selectedIndex, delta != .zero else { return }
        if !moveStepOpen {
            checkpoint()
            moveStepOpen = true
        }
        annotations[index] = annotations[index].translated(by: delta)
    }

    /// Drags a handle of the selected annotation. Call `beginMove()` first; a whole drag is one undo step.
    mutating func resizeSelected(_ handle: ResizeHandle, to point: CGPoint, within bounds: CGRect) {
        guard let index = selectedIndex else { return }
        let resized = annotations[index].resized(dragging: handle, to: point, within: bounds)
        guard resized != annotations[index] else { return }
        if !moveStepOpen {
            checkpoint()
            moveStepOpen = true
        }
        annotations[index] = resized
    }

    mutating func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        restore(previous)
    }

    mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        restore(next)
    }

    private var selectedIndex: Int? { annotations.firstIndex { $0.id == selectedID } }

    private mutating func checkpoint() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    private mutating func restore(_ state: [Annotation]) {
        annotations = state
        if let selectedID, !state.contains(where: { $0.id == selectedID }) { self.selectedID = nil }
    }
}
