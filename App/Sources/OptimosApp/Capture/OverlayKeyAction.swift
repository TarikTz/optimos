import AppKit

/// Maps a key press in the overlay to an action. Pure, so it can be unit-tested.
enum OverlayKeyAction: Equatable {
    case copy
    case save
    case cancel
    case undo
    case redo
    case deleteSelected
    case tool(AnnotationTool)

    /// Esc cancels; Return, keypad Enter and ⌘C copy; ⌘S saves; ⌘Z / ⇧⌘Z undo / redo; Delete removes
    /// the selected annotation; V, R, A, T, P pick a tool. Key auto-repeats map to nothing.
    static func from(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, isRepeat: Bool) -> OverlayKeyAction? {
        guard !isRepeat else { return nil }
        let pressed = modifiers.intersection([.command, .shift, .option, .control])
        let command = pressed == .command
        let plain = pressed.isEmpty
        switch keyCode {
        case 53: return .cancel  // Esc
        case 36, 76: return .copy  // Return, keypad Enter
        case 8 where command: return .copy  // ⌘C
        case 1 where command: return .save  // ⌘S
        case 6 where command: return .undo  // ⌘Z
        case 6 where pressed == [.command, .shift]: return .redo  // ⇧⌘Z
        case 51 where plain, 117 where plain: return .deleteSelected  // Delete, forward delete
        case 9 where plain: return .tool(.select)  // V
        case 15 where plain: return .tool(.rectangle)  // R
        case 0 where plain: return .tool(.arrow)  // A
        case 17 where plain: return .tool(.text)  // T
        case 35 where plain: return .tool(.pixelate)  // P
        default: return nil
        }
    }
}
