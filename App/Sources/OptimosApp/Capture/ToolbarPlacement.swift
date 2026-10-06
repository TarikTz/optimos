import CoreGraphics

enum ToolbarPlacement {
    static let gap: CGFloat = 8
    static let margin: CGFloat = 4

    /// The toolbar frame in display-local points (top-left origin) for a selection: below it at its
    /// right edge, flipped above when there is no room, inside its bottom-right corner when there is
    /// no room outside either, and always clamped inside the display. Because coordinates are
    /// display-local, a display's global origin never matters.
    static func frame(for selection: CGRect, toolbarSize: CGSize, displaySize: CGSize) -> CGRect {
        var x = selection.maxX - toolbarSize.width
        var y = selection.maxY + gap
        if y + toolbarSize.height > displaySize.height - margin {
            y = selection.minY - gap - toolbarSize.height
            if y < margin {
                y = selection.maxY - gap - toolbarSize.height
            }
        }
        x = min(max(x, margin), max(margin, displaySize.width - toolbarSize.width - margin))
        y = min(max(y, margin), max(margin, displaySize.height - toolbarSize.height - margin))
        return CGRect(origin: CGPoint(x: x, y: y), size: toolbarSize)
    }
}
