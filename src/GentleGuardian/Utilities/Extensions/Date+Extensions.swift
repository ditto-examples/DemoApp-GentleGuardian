import Foundation

extension Date {

    /// Returns this date as a "YYYY-MM-DD" string in the current time zone.
    var dateString: String {
        DateService.dateString(from: self)
    }

    /// Returns this date as an ISO 8601 string for Ditto storage.
    var iso8601String: String {
        DateService.iso8601String(from: self)
    }

    /// Returns a relative time string from this date to now (e.g., "3h 12m ago").
    var relativeString: String {
        DateService.relativeTimeString(from: self)
    }

    /// Returns a display-friendly date string (e.g., "Apr 15, 2026").
    var displayDate: String {
        DateService.displayDate(from: self)
    }

    /// Returns a display-friendly time string (e.g., "3:45 PM").
    var displayTime: String {
        DateService.displayTime(from: self)
    }

    /// Returns the start of the calendar day for this date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the calendar day for this date (23:59:59).
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Returns a date offset by the given number of days.
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns whether this date is yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}
