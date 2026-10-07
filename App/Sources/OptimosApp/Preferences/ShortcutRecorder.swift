import AppKit
import SwiftUI

/// A button that shows a shortcut; clicking it records the next key combination. Esc cancels.
struct ShortcutRecorder: View {
    let hotkey: Hotkey?
    let onRecord: (Hotkey) -> Void
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording ? stop() : start()
        } label: {
            Text(isRecording ? "Type shortcut…" : (hotkey?.displayString ?? "Disabled"))
                .frame(minWidth: 110)
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Swallow the key either way so it cannot trigger menu items or beep.
            if let key = Hotkey.from(keyCode: event.keyCode, flags: event.modifierFlags, characters: event.charactersIgnoringModifiers) {
                onRecord(key)
            }
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }
}
