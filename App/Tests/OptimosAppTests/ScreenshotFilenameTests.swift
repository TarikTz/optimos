import Foundation
import Testing

@testable import OptimosApp

@Suite struct ScreenshotFilenameTests {
    @Test func formatsTheDateAsDayAtTime() throws {
        let utc = try #require(TimeZone(identifier: "UTC"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 13, minute: 42, second: 11)))
        #expect(ScreenshotFilename.make(for: date, timeZone: utc) == "Optimos 2026-10-06 at 13.42.11.png")
    }
}
