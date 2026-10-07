import AppKit
import OptimosCore
import SwiftUI

struct PreferencesView: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            saving.tabItem { Label("Saving", systemImage: "square.and.arrow.down") }
            shortcuts.tabItem { Label("Shortcuts", systemImage: "command") }
            optimizer.tabItem { Label("Optimizer", systemImage: "arrow.down.right.and.arrow.up.left") }
            captures.tabItem { Label("Captures", systemImage: "camera.viewfinder") }
        }
        .frame(width: 520, height: 380)
    }

    private var general: some View {
        Form {
            Toggle(
                "Launch OptimosApp at login",
                isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
            if let error = model.launchAtLoginError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    private var saving: some View {
        Form {
            Picker("When saving a screenshot", selection: $model.asksWhereToSave) {
                Text("Ask where to save each time").tag(true)
                Text("Save automatically to the folder below").tag(false)
            }
            .pickerStyle(.radioGroup)
            LabeledContent("Folder") {
                HStack {
                    Text((model.saveDirectory.path as NSString).abbreviatingWithTildeInPath)
                        .lineLimit(1).truncationMode(.middle)
                    Button("Choose…") { chooseFolder() }
                }
            }
            Text("The folder is also where the save panel starts, and it is updated each time you pick one there.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var shortcuts: some View {
        Form {
            ForEach(HotkeyAction.allCases, id: \.self) { action in
                VStack(alignment: .leading, spacing: 2) {
                    LabeledContent(action.menuTitle) {
                        HStack {
                            ShortcutRecorder(hotkey: model.hotkeys[action]) { model.setHotkey($0, for: action) }
                            Button("Reset") { model.resetHotkey(action) }
                            Button("Disable") { model.setHotkey(nil, for: action) }
                                .disabled(model.hotkeys[action] == nil)
                        }
                    }
                    if let error = model.hotkeyErrors[action] {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            Text("Click a shortcut, then press the new combination. It must include ⌃, ⌥ or ⌘. Esc cancels.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private static let sizes = [3840, 2560, 1920, 1280, 800]

    private var optimizer: some View {
        Form {
            Picker("Level", selection: $model.optimizer.level) {
                Text("Lossless").tag(OptimizeLevel.lossless)
                Text("Balanced").tag(OptimizeLevel.balanced)
                Text("Smallest").tag(OptimizeLevel.smallest)
            }
            Picker("Format", selection: $model.optimizer.format) {
                Text("Keep format").tag(ImageFormat?.none)
                Text("PNG").tag(ImageFormat?.some(.png))
                Text("JPEG").tag(ImageFormat?.some(.jpeg))
                Text("WebP").tag(ImageFormat?.some(.webp))
            }
            Picker("Max size", selection: $model.optimizer.maxSide) {
                Text("Original size").tag(Int?.none)
                ForEach(Self.sizes, id: \.self) { Text("Fit \($0) px").tag(Int?.some($0)) }
                if let side = model.optimizer.maxSide, !Self.sizes.contains(side) {
                    Text("Fit \(side) px").tag(Int?.some(side))
                }
            }
            Picker("When the format stays the same", selection: $model.optimizer.replaceOriginals) {
                Text("Replace the original").tag(true)
                Text("Save a copy (name-optimized)").tag(false)
            }
            Picker("Metadata", selection: $model.optimizer.keepMetadata) {
                Text("Remove (credits, captions, location)").tag(false)
                Text("Keep").tag(true)
            }
            Text("WebP output is re-encoded and cannot keep metadata. These are also the settings in the Optimize Images window.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var captures: some View {
        Form {
            Picker("Format when saving", selection: $model.captureFormat) {
                Text("PNG").tag(ImageFormat.png)
                Text("JPEG").tag(ImageFormat.jpeg)
                Text("WebP").tag(ImageFormat.webp)
            }
            Picker("Level", selection: $model.captureLevel) {
                Text("Lossless").tag(OptimizeLevel.lossless)
                Text("Balanced").tag(OptimizeLevel.balanced)
                Text("Smallest").tag(OptimizeLevel.smallest)
            }
            Picker("Max size", selection: $model.captureMaxSide) {
                Text("Original size").tag(Int?.none)
                ForEach(Self.sizes, id: \.self) { Text("Fit \($0) px").tag(Int?.some($0)) }
            }
            Text("The capture toolbar starts from these and lets you change them for one capture. Copy to the clipboard is always PNG, because every app accepts it. The level and max size apply to Copy, Save and Share.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose the folder where screenshots are saved."
        panel.directoryURL = model.saveDirectory
        if panel.runModal() == .OK, let url = panel.url { model.setSaveDirectory(url) }
    }
}
