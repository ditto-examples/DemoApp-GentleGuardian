import Foundation

/// Centralized date formatting and utility functions.
///
/// All date operations go through this service to ensure consistent formatting
/// across the app and proper handling of time zones.
enum DateService {

    // MARK: - Formatters (Thread-Safe)

    /// ISO 8601 formatter with fractional seconds for Ditto storage.
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO 8601 formatter without fractional seconds (fallback for parsing).
    private static let iso8601FallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Date-only formatter for "YYYY-MM-DD" strings.
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    /// Formatter for display-friendly date strings.
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Formatter for display-friendly time strings.
    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - ISO 8601

    /// Converts a Date to an ISO 8601 string for Ditto storage.
    static func iso8601String(from date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    /// Parses an ISO 8601 string to a Date. Tries with and without fractional seconds.
    static func date(fromISO8601 string: String?) -> Date? {
        guard let string else { return nil }
        return iso8601Formatter.date(from: string)
            ?? iso8601FallbackFormatter.date(from: string)
    }

    // MARK: - Date Strings (YYYY-MM-DD)

    /// Returns today's date as a "YYYY-MM-DD" string in the current time zone.
    static func todayString() -> String {
        dateOnlyFormatter.string(from: Date())
    }

    /// Converts a Date to a "YYYY-MM-DD" string in the current time zone.
    static func dateString(from date: Date) -> String {
        dateOnlyFormatter.string(from: date)
    }

    /// Parses a "YYYY-MM-DD" string to a Date.
    static func date(fromDateString string: String) -> Date? {
        dateOnlyFormatter.date(from: string)
    }

    // MARK: - Display Formatting

    /// Returns a display-friendly date string (e.g., "Apr 15, 2026").
    static func displayDate(from date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    /// Returns a display-friendly time string (e.g., "3:45 PM").
    static func displayTime(from date: Date) -> String {
        displayTimeFormatter.string(from: date)
    }

    /// Returns a display-friendly date and time string.
    static func displayDateTime(from date: Date) -> String {
        "\(displayDate(from: date)) at \(displayTime(from: date))"
    }

    // MARK: - Relative Time

    /// Returns a relative time string (e.g., "3h 12m ago", "Just now").
    static func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        guard interval >= 0 else { return "Just now" }

        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if totalMinutes < 1 {
            return "Just now"
        } else if totalMinutes < 60 {
            return "\(totalMinutes)m ago"
        } else if hours < 24 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m ago"
            }
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            if days == 1 {
                return "Yesterday"
            }
            return "\(days) days ago"
        }
    }

    // MARK: - Greeting

    /// Returns a time-of-day-appropriate greeting.
    static func greetingForTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    /// Returns a time-of-day-appropriate subtitle message, rotated daily so it feels fresh.
    ///
    /// Time slots:
    /// - 6 AM – 10 AM: Morning messages
    /// - 10 AM – 2 PM: Midday messages
    /// - 2 PM – 6 PM: Afternoon messages
    /// - 6 PM – 9 PM: Evening messages
    /// - 9 PM – 6 AM: Night messages
    static func subtitleMessageForTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let messages: [String]
        switch hour {
        case 6..<10:
            messages = [
                "Ready to start the day!",
                "A bright new morning begins!",
                "Rise and shine — today is going to be great.",
                "Morning light, tiny smiles. Let's go!",
                "A new day, a new adventure."
            ]
        case 10..<14:
            messages = [
                "Hope the morning is going smoothly!",
                "Midday check-in — you're doing amazing.",
                "Keep up the wonderful work!",
                "Halfway through the day — you've got this!",
                "Fueling up for a great afternoon."
            ]
        case 14..<18:
            messages = [
                "The afternoon adventures continue!",
                "Keeping up the great work this afternoon!",
                "Almost through another wonderful day!",
                "Afternoon is in full swing — you're a star.",
                "The day is winding toward a beautiful evening."
            ]
        case 18..<21:
            messages = [
                "A beautiful evening with the family!",
                "Winding down after a wonderful day.",
                "Evening time — you did great today!",
                "The golden hour — well done today.",
                "Almost time to rest — you've earned it!"
            ]
        default:
            messages = [
                "Sweet dreams are almost here.",
                "Rest up — you've earned it!",
                "A peaceful night for the whole family.",
                "Night watch: on. You've got this.",
                "Quiet moments, cozy nights."
            ]
        }
        // Rotate by day-of-year so the message is stable within a day but changes daily.
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return messages[dayOfYear % messages.count]
    }

    // MARK: - Tracking Day

    /// Determines whether a given date falls within the defined tracking day boundaries.
    ///
    /// The tracking day can span midnight. For example, if `startHour` is 6 and
    /// `endHour` is 6, it represents a full 24-hour day from 6 AM to 6 AM.
    ///
    /// - Parameters:
    ///   - date: The date to check.
    ///   - startHour: The hour (0-23) when the tracking day begins.
    ///   - endHour: The hour (0-23) when the tracking day ends.
    /// - Returns: `true` if the date falls within the tracking day.
    static func isWithinTrackingDay(date: Date, startHour: Int, endHour: Int) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if startHour == endHour {
            // Equal hours = full 24-hour day
            return true
        } else if startHour < endHour {
            // Same-day range (e.g., 6 AM to 10 PM)
            return hour >= startHour && hour < endHour
        } else {
            // Overnight range (e.g., 8 PM to 4 AM)
            return hour >= startHour || hour < endHour
        }
    }

    /// Returns the start-of-tracking-day Date for a given reference date.
    ///
    /// - Parameters:
    ///   - referenceDate: The date to calculate the tracking day start for.
    ///   - startHour: The hour (0-23) when the tracking day begins.
    /// - Returns: A Date representing the start of the tracking day.
    static func trackingDayStart(for referenceDate: Date, startHour: Int) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: referenceDate)

        var dateToUse = referenceDate
        // If we're before the start hour, the tracking day started yesterday
        if hour < startHour {
            dateToUse = calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        }

        return calendar.date(
            bySettingHour: startHour,
            minute: 0,
            second: 0,
            of: dateToUse
        ) ?? referenceDate
    }
}
