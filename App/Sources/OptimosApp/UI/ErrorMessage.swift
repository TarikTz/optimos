import Foundation
import OptimosCore

/// Turns an error into one short human-readable line for a toast.
enum ErrorMessage {
    /// Our own error types describe themselves well; everything else (for example ScreenCaptureKit's
    /// NSError) is shown through `localizedDescription` instead of the raw `NSError` dump.
    static func text(for error: Error) -> String {
        switch error {
        case let error as CaptureError: String(describing: error)
        case let error as OutputError: String(describing: error)
        case let error as OptimosError: String(describing: error)
        default: error.localizedDescription
        }
    }
}
