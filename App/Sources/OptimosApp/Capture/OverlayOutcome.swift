import CoreGraphics
import OptimosCore

/// What to do with a confirmed selection.
enum CaptureAction: Equatable, Sendable {
    case copy
    case save
    case share
}

/// What the overlay returns: the selection, the action chosen on the toolbar and the annotations
/// drawn on it (display-local points).
struct OverlayOutcome: Equatable, Sendable {
    let selection: CaptureSelection
    let action: CaptureAction
    var annotations: [Annotation] = []
    /// The output choices shown on the toolbar for this capture.
    var output: OutputChoice = OutputChoice(format: .png, maxSide: nil)
    /// Where the toolbar was, in display-local points (top-left origin); the share menu opens there.
    var toolbarFrame: CGRect = .zero
}

/// Format and longest-side limit for one capture. Copy ignores the format (always PNG).
struct OutputChoice: Equatable, Sendable {
    var format: ImageFormat
    /// nil keeps the original size.
    var maxSide: Int?
}
