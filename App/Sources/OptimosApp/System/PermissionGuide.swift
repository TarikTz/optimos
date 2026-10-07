import AppKit

/// Walks the user through the Screen Recording permission: asks, opens the right Settings pane, waits
/// for access to turn on, then offers the one restart macOS needs before capturing works.
@MainActor
final class PermissionGuide {
    private let permission: PermissionService
    private var timer: Timer?
    private var deadline = Date.distantPast

    init(permission: PermissionService) {
        self.permission = permission
    }

    /// Starts (or restarts) the walkthrough. Safe to call repeatedly.
    func begin() {
        guard !permission.isGranted else {
            offerRestart()
            return
        }
        permission.request()
        permission.openSystemSettings()
        deadline = Date().addingTimeInterval(180)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    private func poll() {
        if permission.isGranted {
            timer?.invalidate()
            timer = nil
            offerRestart()
        } else if Date() > deadline {
            timer?.invalidate()
            timer = nil
        }
    }

    private func offerRestart() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Screen Recording is on"
        alert.informativeText = "OptimosApp has to restart once before it can capture. Restart now?"
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn { Self.relaunch() }
    }

    /// Starts a fresh copy of the app a moment after this one quits.
    static func relaunch() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.7; /usr/bin/open -n \"$0\"", Bundle.main.bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }
}
