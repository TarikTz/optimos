import AppKit
import OptimosCore
import SwiftUI

struct OptimizerView: View {
    @Bindable var model: OptimizerViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if model.rows.isEmpty {
                    dropPrompt
                } else {
                    List(model.rows) { row in OptimizerRowView(row: row) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isTargeted ? Color.accentColor.opacity(0.12) : Color.clear)
            .dropDestination(for: URL.self) { urls, _ in
                model.add(urls)
                return true
            } isTargeted: { isTargeted = $0 }

            Divider()
            Text("Files are replaced in place. Undo restores them until you close this window. Converting writes a new file.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            OptimizerBar(model: model)
        }
        .frame(minWidth: 620, minHeight: 360)
    }

    private var dropPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: 54, weight: .light))
            Text("Drop images or folders here")
                .font(.title3)
            Text("PNG, JPEG, WebP, plus HEIC, TIFF and BMP to convert")
                .font(.callout)
        }
        .foregroundStyle(.secondary)
    }
}

private struct OptimizerRowView: View {
    let row: OptimizerRow

    var body: some View {
        HStack {
            Text(row.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
            Spacer()
            switch row.status {
            case .queued: Text("Waiting").foregroundStyle(.secondary)
            case .working: ProgressView().controlSize(.small)
            case .restored: Text("Restored").foregroundStyle(.secondary)
            case .failed(let message): Text(message).foregroundStyle(.red).lineLimit(2)
            case .done(let result): Text(Self.summary(result)).foregroundStyle(.secondary)
            }
        }
    }

    private static func format(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    static func summary(_ result: FileJobResult) -> String {
        if case .alreadyOptimal = result.outcome { return "Already optimal" }
        let percent = Int((result.savedFraction * 100).rounded())
        let sizes = "\(format(result.originalBytes)) → \(format(result.newBytes)) (\(percent > 0 ? "−" : "+")\(abs(percent))%)"
        if case .converted(let output) = result.outcome { return "\(output.lastPathComponent)  \(sizes)" }
        return sizes
    }
}

private struct OptimizerBar: View {
    @Bindable var model: OptimizerViewModel
    @State private var customText = ""

    private static let presets = [3840, 2560, 1920, 1280, 800]

    var body: some View {
        HStack(spacing: 14) {
            Button { chooseFiles() } label: { Image(systemName: "plus") }
                .help("Add images or folders")
            Picker("Level", selection: $model.settings.level) {
                Text("Lossless").tag(OptimizeLevel.lossless)
                Text("Balanced").tag(OptimizeLevel.balanced)
                Text("Smallest").tag(OptimizeLevel.smallest)
            }
            .fixedSize()
            Picker("Format", selection: $model.settings.format) {
                Text("Keep format").tag(ImageFormat?.none)
                Text("PNG").tag(ImageFormat?.some(.png))
                Text("JPEG").tag(ImageFormat?.some(.jpeg))
                Text("WebP").tag(ImageFormat?.some(.webp))
            }
            .fixedSize()
            Picker("Max size", selection: $model.settings.maxSide) {
                Text("Original size").tag(Int?.none)
                ForEach(Self.presets, id: \.self) { Text("Fit \($0) px").tag(Int?.some($0)) }
                if let side = model.settings.maxSide, !Self.presets.contains(side) {
                    Text("Fit \(side) px").tag(Int?.some(side))
                }
            }
            .fixedSize()
            TextField("Custom px", text: $customText)
                .frame(width: 80)
                .onSubmit {
                    if let side = Int(customText), side > 0 { model.settings.maxSide = side }
                    customText = ""
                }
                .help("Type a longest-side size in pixels and press Return")
            Spacer()
            Button("Undo") { model.undo() }.disabled(!model.canUndo)
            Button("Again") { model.runAgain() }.disabled(!model.canRunAgain)
        }
        .labelsHidden()
        .padding(12)
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png, .jpeg, .webP, .heic, .heif, .tiff, .bmp, .folder]
        panel.prompt = "Add"
        if panel.runModal() == .OK { model.add(panel.urls) }
    }
}
