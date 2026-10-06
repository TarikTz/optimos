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
}
