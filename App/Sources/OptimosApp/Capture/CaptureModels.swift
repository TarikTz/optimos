import CoreGraphics

/// A display and the geometry needed to map selections to pixels. Frames use the
/// ScreenCaptureKit / CoreGraphics global space: points, origin at the top-left of the primary display.
struct DisplayInfo: Equatable, Sendable {
    let id: CGDirectDisplayID
    let frame: CGRect
}

/// A frozen capture of one display. `image` is in pixels (2x on Retina).
struct FrozenDisplay: @unchecked Sendable {
    let info: DisplayInfo
    let image: CGImage
}

/// A normal on-screen window. `frame` is in the same global space as `DisplayInfo.frame`.
struct WindowInfo: Equatable, Sendable {
    let id: CGWindowID
    let frame: CGRect
    let layer: Int
    let title: String
    let appName: String
}

/// What the user picked: a rectangle in points, relative to the top-left of the display's frame.
struct CaptureSelection: Equatable, Sendable {
    let displayID: CGDirectDisplayID
    let rect: CGRect
}
