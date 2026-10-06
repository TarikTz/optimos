import CoreGraphics

/// What to do with a confirmed selection.
enum CaptureAction: Equatable, Sendable {
    case copy
    case save
}

/// What the overlay returns: the selection, the action chosen on the toolbar and the annotations
/// drawn on it (display-local points).
struct OverlayOutcome: Equatable, Sendable {
    let selection: CaptureSelection
    let action: CaptureAction
    var annotations: [Annotation] = []
}
