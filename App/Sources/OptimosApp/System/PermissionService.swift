import AppKit
import CoreGraphics

struct PermissionService: Sendable {
    var isGranted: Bool { CGPreflightScreenCaptureAccess() }

    /// Shows the system prompt the first time. Afterwards macOS shows nothing, so callers must
    /// also tell the user how to grant access.
    @discardableResult
    func request() -> Bool { CGRequestScreenCaptureAccess() }

    @MainActor
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
