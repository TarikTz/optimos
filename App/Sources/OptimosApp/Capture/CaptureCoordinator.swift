import AppKit
import CoreGraphics

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
    private var isBusy = false

    init(
        capture: CaptureService, output: OutputService, permission: PermissionService,
        toast: ToastPresenter, overlay: SelectionOverlayController, saveLocation: SaveLocationStore
    ) {
        self.capture = capture
        self.output = output
        self.permission = permission
        self.toast = toast
        self.overlay = overlay
        self.saveLocation = saveLocation
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
            permission.request()
            toast.show(
                "Allow Screen Recording for OptimosApp in System Settings, then restart. If already on, remove OptimosApp from the list and add it again.",
                isWarning: true, duration: 5)
            return
        }
        do {
            switch action {
            case .captureScreen: try await captureScreen()
            case .captureArea: try await captureArea()
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
        try await deliver(frozen.image, save: false)
    }

    private func captureArea() async throws {
        // Freeze the screens BEFORE any overlay exists, so the overlay can never be captured.
        async let windows: [WindowInfo] = (try? await capture.onScreenWindows()) ?? []
        let frozen = try await capture.captureAllDisplays()
        let outcome = await overlay.run(displays: frozen, windows: await windows)
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
        try await deliver(final, save: outcome.action == .save)
    }

    private func deliver(_ image: CGImage, save: Bool) async throws {
        guard save else {
            let result = try await output.copy(image)
            toast.show(result.toastMessage, isWarning: result.warning != nil)
            return
        }
        do {
            let result = try await output.save(image)
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
