import AppKit
import CoreGraphics

/// The only place the capture flow is wired together:
/// hotkey -> permission -> capture -> output -> toast.
@MainActor
final class CaptureCoordinator {
    private let capture: CaptureService
    private let output: OutputService
    private let permission: PermissionService
    private let toast: ToastPresenter
    private var isBusy = false

    init(capture: CaptureService, output: OutputService, permission: PermissionService, toast: ToastPresenter) {
        self.capture = capture
        self.output = output
        self.permission = permission
        self.toast = toast
    }

    func perform(_ action: HotkeyAction) {
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
            case .captureScreen:
                try await captureScreen()
            case .captureArea, .captureAndSave:
                toast.show("Area capture arrives in the next step", isWarning: true)
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

    private func deliver(_ image: CGImage, save: Bool) async throws {
        let result = save ? try await output.save(image) : try await output.copy(image)
        toast.show(result.toastMessage, isWarning: result.warning != nil)
    }
}
