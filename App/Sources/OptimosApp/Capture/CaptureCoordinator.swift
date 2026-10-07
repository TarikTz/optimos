import AppKit
import CoreGraphics
import OptimosCore
import UniformTypeIdentifiers

/// The only place the capture flow is wired together:
/// hotkey -> permission -> freeze screens -> overlay (select, then Copy or Save) -> crop -> output -> toast.
@MainActor
final class CaptureCoordinator {
    private let capture: CaptureService
    private let output: OutputService
    private let permission: PermissionService
    private let toast: ToastPresenter
    private let overlay: SelectionOverlayController
    private let saveLocation: SaveLocationStore
    private let captureSettings: CaptureSettingsStore
    private let sharePresenter = SharePresenter()
    private let permissionGuide: PermissionGuide
    private var isBusy = false

    init(
        capture: CaptureService, output: OutputService, permission: PermissionService,
        toast: ToastPresenter, overlay: SelectionOverlayController, saveLocation: SaveLocationStore,
        captureSettings: CaptureSettingsStore = CaptureSettingsStore(), permissionGuide: PermissionGuide? = nil
    ) {
        self.capture = capture
        self.output = output
        self.permission = permission
        self.toast = toast
        self.overlay = overlay
        self.saveLocation = saveLocation
        self.captureSettings = captureSettings
        self.permissionGuide = permissionGuide ?? PermissionGuide(permission: permission)
    }

    func perform(_ action: HotkeyAction) {
        if overlay.isActive {  // pressing a capture hotkey again dismisses the overlay
            overlay.cancel()
            return
        }
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            await run(action)
        }
    }

    private func run(_ action: HotkeyAction) async {
        guard permission.isGranted else {
            permissionGuide.begin()
            toast.show(
                "Allow OptimosApp under Screen & System Audio Recording and it will offer to restart. If it is already listed but not working, remove it with − and add it again.",
                isWarning: true, duration: 6)
            return
        }
        do {
            switch action {
            case .captureScreen: try await captureScreen()
            case .captureArea: try await captureArea()
            case .openOptimizer: break  // handled by the app delegate, not a capture
            }
        } catch {
            toast.show("Capture failed: \(ErrorMessage.text(for: error))", isWarning: true, duration: 4)
        }
    }

    private func captureScreen() async throws {
        guard let id = (NSScreen.containingMouse() ?? NSScreen.main)?.displayID else {
            throw CaptureError.noDisplays
        }
        let frozen = try await capture.captureDisplay(id: id)
        let result = try await output.copy(frozen.image)
        toast.show(result.toastMessage, isWarning: result.warning != nil)
    }

    private func captureArea() async throws {
        // Freeze the screens BEFORE any overlay exists, so the overlay can never be captured.
        async let windows: [WindowInfo] = (try? await capture.onScreenWindows()) ?? []
        let frozen = try await capture.captureAllDisplays()
        let outcome = await overlay.run(
            displays: frozen, windows: await windows,
            outputDefaults: OutputChoice(format: captureSettings.format, maxSide: captureSettings.maxSide))
        guard let outcome,
            let display = frozen.first(where: { $0.info.id == outcome.selection.displayID })
        else {
            return  // cancelled
        }
        guard
            let cropRect = CaptureGeometry.pixelCropRect(
                for: outcome.selection.rect, displaySize: display.info.frame.size,
                imageSize: CGSize(width: display.image.width, height: display.image.height)),
            let cropped = display.image.cropping(to: cropRect)
        else { throw CaptureError.cropFailed }
        let scale = CGFloat(display.image.width) / display.info.frame.width
        guard
            let final = AnnotatedImageExporter.render(
                cropped: cropped, annotations: outcome.annotations,
                cropOrigin: CGPoint(x: cropRect.minX / scale, y: cropRect.minY / scale), pointScale: scale)
        else { throw CaptureError.annotationFailed }
        try await deliver(final, outcome: outcome, display: display)
    }

    /// Asks where to save this screenshot, starting in the remembered folder.
    private func chooseSaveFile(format: ImageFormat) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format == .png ? .png : format == .jpeg ? .jpeg : .webP]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = ScreenshotFilename.make(for: Date(), fileExtension: format.fileExtension)
        panel.message = "Choose where to save the screenshot."
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: saveLocation.directory.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        {
            panel.directoryURL = saveLocation.directory
        }
        // An accessory app is not frontmost by default, and the panel would open behind other windows.
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func deliver(_ image: CGImage, outcome: OverlayOutcome, display: FrozenDisplay) async throws {
        switch outcome.action {
        case .copy:
            let result = try await output.copy(image, choice: outcome.output)
            toast.show(result.toastMessage, isWarning: result.warning != nil)
        case .save:
            try await save(image, choice: outcome.output)
        case .share:
            let file = try await output.exportForSharing(image, choice: outcome.output)
            sharePresenter.share(file, near: Self.screenRect(of: outcome.toolbarFrame, on: display.info.id))
            // The file is a private copy for the share menu; remove it once any transfer has had time to finish.
            Task {
                try? await Task.sleep(for: .seconds(900))
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// Display-local top-left points to AppKit screen coordinates.
    private static func screenRect(of local: CGRect, on displayID: CGDirectDisplayID) -> CGRect {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else {
            return CGRect(origin: NSEvent.mouseLocation, size: .zero)
        }
        return CGRect(
            x: screen.frame.minX + local.minX, y: screen.frame.maxY - local.maxY,
            width: local.width, height: local.height)
    }

    private func save(_ image: CGImage, choice: OutputChoice) async throws {
        var destination: URL?
        if saveLocation.asksWhereToSave {
            guard let chosen = chooseSaveFile(format: choice.format) else { return }  // cancelled: nothing is saved
            destination = chosen
            saveLocation.setDirectory(chosen.deletingLastPathComponent())
        }
        do {
            let result = try await output.save(image, to: destination, choice: choice)
            if case .file(let url) = result.destination { saveLocation.setLastSavedFile(url) }
            toast.show(result.toastMessage, isWarning: result.warning != nil)
        } catch OutputError.cannotWrite(let why) {
            // Never save somewhere else silently: say what failed and how to fix it.
            toast.show(
                "Save failed: \(why). Choose another folder with Save Location… in the menu.",
                isWarning: true, duration: 5)
        }
    }
}
