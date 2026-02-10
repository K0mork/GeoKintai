import Foundation

private let appDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

extension Date {
    var shortDateTime: String {
        appDateTimeFormatter.string(from: self)
    }
}
