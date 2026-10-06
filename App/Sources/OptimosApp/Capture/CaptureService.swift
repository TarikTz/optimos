import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

protocol CaptureService: Sendable {
    func captureAllDisplays() async throws -> [FrozenDisplay]
    func captureDisplay(id: CGDirectDisplayID) async throws -> FrozenDisplay
    /// Normal windows currently on screen, ordered front to back.
    func onScreenWindows() async throws -> [WindowInfo]
}

enum CaptureError: Error, CustomStringConvertible {
    case noDisplays
    case displayNotFound
    case cropFailed
    case annotationFailed

    var description: String {
        switch self {
        case .noDisplays: "no display found"
        case .displayNotFound: "that display is no longer available"
        case .cropFailed: "the selection was outside the screen"
        case .annotationFailed: "the annotations could not be added to the image"
        }
    }
}

/// SCWindow is an immutable snapshot object that is not annotated Sendable; it is only read concurrently.
private struct OwnWindows: @unchecked Sendable {
    let windows: [SCWindow]
}

private struct DisplayBox: @unchecked Sendable {
    let display: SCDisplay
}

struct ScreenCaptureKitService: CaptureService {
    func captureAllDisplays() async throws -> [FrozenDisplay] {
        let content = try await Self.shareableContent()
        guard !content.displays.isEmpty else { throw CaptureError.noDisplays }
        let own = OwnWindows(windows: Self.ownWindows(in: content))
        return try await withThrowingTaskGroup(of: FrozenDisplay.self) { group in
            for display in content.displays {
                let box = DisplayBox(display: display)
                group.addTask { try await Self.capture(box.display, excluding: own.windows) }
            }
            var frozen: [FrozenDisplay] = []
            for try await display in group { frozen.append(display) }
            return frozen
        }
    }

    func captureDisplay(id: CGDirectDisplayID) async throws -> FrozenDisplay {
        let content = try await Self.shareableContent()
        guard let display = content.displays.first(where: { $0.displayID == id }) else {
            throw CaptureError.displayNotFound
        }
        return try await Self.capture(display, excluding: Self.ownWindows(in: content))
    }

    func onScreenWindows() async throws -> [WindowInfo] {
        let content = try await Self.shareableContent()
        let order = Self.frontToBackOrder()
        let me = ProcessInfo.processInfo.processIdentifier
        return content.windows
            .filter {
                $0.isOnScreen && $0.windowLayer == 0 && $0.owningApplication?.processID != me
                    && $0.frame.width >= 40 && $0.frame.height >= 40
            }
            .sorted { (order[$0.windowID] ?? .max) < (order[$1.windowID] ?? .max) }
            .map {
                WindowInfo(
                    id: $0.windowID, frame: $0.frame, layer: $0.windowLayer,
                    title: $0.title ?? "", appName: $0.owningApplication?.applicationName ?? "")
            }
    }

    // MARK: - Helpers

    private static func shareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    /// Our own windows (overlay, toast) are always excluded so they can never appear in a capture.
    private static func ownWindows(in content: SCShareableContent) -> [SCWindow] {
        let me = ProcessInfo.processInfo.processIdentifier
        return content.windows.filter { $0.owningApplication?.processID == me }
    }

    private static func capture(_ display: SCDisplay, excluding own: [SCWindow]) async throws -> FrozenDisplay {
        let filter = SCContentFilter(display: display, excludingWindows: own)
        let scale = CGFloat(filter.pointPixelScale)
        let configuration = SCStreamConfiguration()
        configuration.width = Int((CGFloat(display.width) * scale).rounded())
        configuration.height = Int((CGFloat(display.height) * scale).rounded())
        configuration.showsCursor = false
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        return FrozenDisplay(info: DisplayInfo(id: display.displayID, frame: display.frame), image: image)
    }

    /// Window id -> position, 0 being the front-most window.
    private static func frontToBackOrder() -> [CGWindowID: Int] {
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]] ?? []
        var order: [CGWindowID: Int] = [:]
        for (index, entry) in info.enumerated() {
            if let number = (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value {
                order[number] = index
            }
        }
        return order
    }
}
