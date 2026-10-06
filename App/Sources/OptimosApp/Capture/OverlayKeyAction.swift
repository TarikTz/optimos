import AppKit

/// Maps a key press in the overlay to an action. Pure, so it can be unit-tested.
enum OverlayKeyAction: Equatable {
    case copy
    case save
    case cancel

    /// Esc cancels; Return, keypad Enter and ⌘C copy; ⌘S saves. Key auto-repeats map to nothing.
    static func from(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, isRepeat: Bool) -> OverlayKeyAction? {
        guard !isRepeat else { return nil }
        let command = modifiers.intersection([.command, .shift, .option, .control]) == .command
        switch keyCode {
        case 53: return .cancel  // Esc
        case 36, 76: return .copy  // Return, keypad Enter
        case 8 where command: return .copy  // ⌘C
        case 1 where command: return .save  // ⌘S
        default: return nil
        }
    }
}
