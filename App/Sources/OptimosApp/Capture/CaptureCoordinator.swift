import AppKit
import CoreGraphics

/// The only place the capture flow is wired together:
/// hotkey -> permission -> freeze screens -> overlay -> crop -> output -> toast.
@MainActor
final class CaptureCoordinator {
    private let capture: CaptureService
    private let output: OutputService
    private let permission: PermissionService
    private let toast: ToastPresenter
    private let overlay: SelectionOverlayController
    private var isBusy = false

    init(
        capture: CaptureService, output: OutputService, permission: PermissionService,
        toast: ToastPresenter, overlay: SelectionOverlayController
    ) {
        self.capture = capture
        self.output = output
        self.permission = permission
        self.toast = toast
        self.overlay = overlay
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
                "Allow Screen Recording for OptimosApp in System Settings, then restart the app",
                isWarning: true, duration: 5)
            return
        }
        do {
            switch action {
            case .captureScreen: try await captureScreen()
            case .captureArea: try await captureArea(save: false)
            case .captureAndSave: try await captureArea(save: true)
            }
        } catch {
            toast.show("Capture failed: \(error)", isWarning: true, duration: 4)
        }
    }

    private func captureScreen() async throws {
        guard let id = (NSScreen.containingMouse() ?? NSScreen.main)?.displayID else {
            throw CaptureError.noDisplays
        }
        let frozen = try await capture.captureDisplay(id: id)
        try await deliver(frozen.image, save: false)
    }

    private func captureArea(save: Bool) async throws {
        // Freeze the screens BEFORE any overlay exists, so the overlay can never be captured.
        let frozen = try await capture.captureAllDisplays()
        let selection = await overlay.run(displays: frozen)
        guard let selection, let display = frozen.first(where: { $0.info.id == selection.displayID }) else {
            return  // cancelled
        }
        guard
            let cropRect = CaptureGeometry.pixelCropRect(
                for: selection.rect, displaySize: display.info.frame.size,
                imageSize: CGSize(width: display.image.width, height: display.image.height)),
            let cropped = display.image.cropping(to: cropRect)
        else { throw CaptureError.cropFailed }
        try await deliver(cropped, save: save)
    }

    private func deliver(_ image: CGImage, save: Bool) async throws {
        let result = save ? try await output.save(image) : try await output.copy(image)
        toast.show(result.toastMessage, isWarning: result.warning != nil)
    }
}
