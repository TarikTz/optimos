import CoreGraphics

/// What to do with a confirmed selection.
enum CaptureAction: Equatable, Sendable {
    case copy
    case save
}

/// What the overlay returns: the selection and the action chosen on the toolbar.
struct OverlayOutcome: Equatable, Sendable {
    let selection: CaptureSelection
    let action: CaptureAction
}
