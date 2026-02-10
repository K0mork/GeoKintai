import Foundation
import Testing
@testable import geoKintai

@Suite("TimeZoneConversionTests")
struct TimeZoneConversionTests {
    @Test("NFC-01: test_timeZoneConversion_whenStored_keepsAbsoluteDate")
    func test_timeZoneConversion_whenStored_keepsAbsoluteDate() {
        let original = Date(timeIntervalSince1970: 1_700_230_000)
        let stored = UTCDateConverter.toStorageDate(original)

        #expect(stored.timeIntervalSince1970 == original.timeIntervalSince1970)
    }

    @Test("NFC-01: test_timeZoneConversion_whenDisplay_convertsToTargetTimeZone")
    func test_timeZoneConversion_whenDisplay_convertsToTargetTimeZone() {
        let date = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 00:00:00 UTC
        let utc = TimeZone(secondsFromGMT: 0)!
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!

        let utcText = UTCDateConverter.displayString(date, timeZone: utc)
        let tokyoText = UTCDateConverter.displayString(date, timeZone: tokyo)

        #expect(utcText == "2024-01-01 00:00")
        #expect(tokyoText == "2024-01-01 09:00")
    }
}
