import Foundation

public enum UTCDateConverter {
    public static func toStorageDate(_ date: Date) -> Date {
        // Date is absolute in Swift; storage uses this value directly as UTC reference.
        date
    }

    public static func displayString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
