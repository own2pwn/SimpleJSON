import Foundation

public extension DateFormatter {

    /// A date formatter configured to accept ISO8610 date formats using the en_US_POSIX
    ///  locale and a UTC time zone. Suitable for parsing dates from the API.
    public static let iso8601UTCDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
