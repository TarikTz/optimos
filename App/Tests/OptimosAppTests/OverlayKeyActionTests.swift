import AppKit
import Testing

@testable import OptimosApp

@Suite struct OverlayKeyActionTests {
    private func action(_ code: UInt16, _ flags: NSEvent.ModifierFlags = [], isRepeat: Bool = false) -> OverlayKeyAction? {
        OverlayKeyAction.from(keyCode: code, modifiers: flags, isRepeat: isRepeat)
    }

    @Test func escapeCancels() {
        #expect(action(53) == .cancel)
    }

    @Test func returnAndKeypadEnterCopy() {
        #expect(action(36) == .copy)
        #expect(action(76) == .copy)
    }

    @Test func commandCCopiesAndCommandSSaves() {
        #expect(action(8, .command) == .copy)
        #expect(action(1, .command) == .save)
    }

    @Test func plainCAndSDoNothing() {
        #expect(action(8) == nil)
        #expect(action(1) == nil)
    }

    @Test func otherCommandCombinationsDoNothing() {
        #expect(action(8, [.command, .shift]) == nil)
        #expect(action(1, .option) == nil)
    }

    @Test func keyAutoRepeatDoesNothing() {
        #expect(action(36, isRepeat: true) == nil)
        #expect(action(53, isRepeat: true) == nil)
    }

    @Test func capsLockDoesNotBreakCommandShortcuts() {
        #expect(action(8, [.command, .capsLock]) == .copy)
        #expect(action(1, [.command, .capsLock]) == .save)
    }

    @Test func functionAndNumericPadFlagsDoNotBreakCommandC() {
        #expect(action(8, [.command, .function]) == .copy)
        #expect(action(8, [.command, .numericPad]) == .copy)
    }

    @Test func realExtraModifiersStillBlockShortcutsWithCapsLockOn() {
        #expect(action(8, [.command, .shift, .capsLock]) == nil)
        #expect(action(1, [.option, .capsLock]) == nil)
    }

    @Test func undoRedoDeleteAndToolKeys() {
        #expect(action(6, .command) == .undo)
        #expect(action(6, [.command, .shift]) == .redo)
        #expect(action(6) == nil)
        #expect(action(51) == .deleteSelected)
        #expect(action(117) == .deleteSelected)
        #expect(action(15) == .tool(.rectangle))
        #expect(action(0) == .tool(.arrow))
        #expect(action(17) == .tool(.text))
        #expect(action(35) == .tool(.pixelate))
        #expect(action(9) == .tool(.select))
        #expect(action(15, .command) == nil)
        #expect(action(31) == .tool(.ellipse))
        #expect(action(37) == .tool(.line))
        #expect(action(4) == .tool(.highlight))
        #expect(action(45) == .tool(.marker))
        #expect(action(11) == .tool(.blur))
    }
}
