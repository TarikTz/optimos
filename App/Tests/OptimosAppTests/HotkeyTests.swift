import Carbon.HIToolbox
import Testing

@testable import OptimosApp

@Suite struct HotkeyTests {
    @Test func everyActionHasADefaultHotkey() {
        for action in HotkeyAction.allCases {
            #expect(Hotkey.defaults[action] != nil)
        }
    }

    @Test func defaultsAreDistinctAndAvoidTheSystemScreenshotShortcuts() {
        let keys = HotkeyAction.allCases.compactMap { Hotkey.defaults[$0] }
        #expect(Set(keys.map(\.keyCode)).count == keys.count)
        let system = UInt32(cmdKey | shiftKey)
        for key in keys { #expect(key.modifiers != system) }
    }

    @Test func rendersTheShortcutForTheMenu() {
        #expect(Hotkey.defaults[.captureArea]?.displayString == "⌃⌥⌘4")
        #expect(Hotkey.defaults[.captureScreen]?.displayString == "⌃⌥⌘3")
        #expect(Hotkey.defaults[.captureAndSave]?.displayString == "⌃⌥⌘5")
    }
}
