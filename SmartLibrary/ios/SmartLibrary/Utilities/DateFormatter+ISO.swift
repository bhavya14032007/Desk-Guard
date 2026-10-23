import Foundation

enum AppDateFormatter {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Parses an ISO-8601 string from Postgres into a Swift Date
    static func parseISO(_ string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }
        if let date = isoFormatter.date(from: string) {
            return date
        }
        return isoFormatterNoFractions.date(from: string)
    }

    /// Formats a Date to a friendly localized time string (e.g. 10:45 AM)
    static func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        return displayTimeFormatter.string(from: date)
    }

    /// Formats a Date to a friendly localized full date and time string
    static func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        return displayDateFormatter.string(from: date)
    }

    /// Calculates remaining seconds from now until the grace deadline
    static func remainingSeconds(until deadlineString: String?) -> Int {
        guard let deadline = parseISO(deadlineString) else { return 0 }
        let diff = deadline.timeIntervalSince(Date())
        return max(0, Int(diff))
    }

    /// Formats remaining seconds to mm:ss countdown format
    static func formatCountdown(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
