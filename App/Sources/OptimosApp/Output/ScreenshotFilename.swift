import Foundation

enum ScreenshotFilename {
    /// "Optimos 2026-10-06 at 13.42.11.png"
    static func make(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Optimos \(formatter.string(from: date)).png"
    }
}
