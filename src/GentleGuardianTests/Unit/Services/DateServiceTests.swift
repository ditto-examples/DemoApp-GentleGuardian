import Testing
import Foundation
@testable import GentleGuardian

/// Tests for DateService utility functions.
@Suite("DateService Tests")
struct DateServiceTests {

    @Test("ISO 8601 round-trip preserves date")
    func iso8601RoundTrip() {
        let original = Date(timeIntervalSince1970: 1700000000)
        let string = DateService.iso8601String(from: original)
        let restored = DateService.date(fromISO8601: string)

        #expect(restored != nil)
        // Allow 1 millisecond tolerance for fractional seconds
        if let restored {
            #expect(abs(original.timeIntervalSince(restored)) < 0.001)
        }
    }

    @Test("todayString returns YYYY-MM-DD format")
    func todayStringFormat() {
        let today = DateService.todayString()
        let parts = today.split(separator: "-")

        #expect(parts.count == 3)
        #expect(parts[0].count == 4) // year
        #expect(parts[1].count == 2) // month
        #expect(parts[2].count == 2) // day
    }

    @Test("dateString from Date matches expected format")
    func dateStringFormat() {
        // Create a known date: January 5, 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 5
        components.hour = 12

        let date = Calendar.current.date(from: components)!
        let result = DateService.dateString(from: date)

        #expect(result == "2026-01-05")
    }

    @Test("relativeTimeString for recent dates")
    func relativeTimeRecent() {
        let justNow = Date()
        #expect(DateService.relativeTimeString(from: justNow) == "Just now")

        let fiveMinAgo = Date().addingTimeInterval(-300)
        let result = DateService.relativeTimeString(from: fiveMinAgo)
        #expect(result == "5m ago")
    }

    @Test("relativeTimeString for hours ago")
    func relativeTimeHours() {
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        let result = DateService.relativeTimeString(from: twoHoursAgo)
        #expect(result.contains("2h"))
    }

    @Test("greetingForTimeOfDay returns non-empty string")
    func greetingNotEmpty() {
        let greeting = DateService.greetingForTimeOfDay()
        #expect(!greeting.isEmpty)
        #expect(greeting.hasPrefix("Good"))
    }

    @Test("isWithinTrackingDay same-day range")
    func trackingDaySameDay() {
        // 6 AM to 10 PM range
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 15
        components.hour = 12 // noon
        let noon = Calendar.current.date(from: components)!

        #expect(DateService.isWithinTrackingDay(date: noon, startHour: 6, endHour: 22))

        components.hour = 3 // 3 AM
        let earlyMorning = Calendar.current.date(from: components)!
        #expect(!DateService.isWithinTrackingDay(date: earlyMorning, startHour: 6, endHour: 22))
    }

    @Test("isWithinTrackingDay overnight range")
    func trackingDayOvernight() {
        // 6 AM to 6 AM = full 24 hours
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 15
        components.hour = 3 // 3 AM

        let earlyMorning = Calendar.current.date(from: components)!
        // With startHour=6, endHour=6 (overnight wrap), 3 AM is < endHour so it's in range
        #expect(DateService.isWithinTrackingDay(date: earlyMorning, startHour: 6, endHour: 6))
    }

    @Test("date from nil ISO 8601 string returns nil")
    func dateFromNilString() {
        let result = DateService.date(fromISO8601: nil)
        #expect(result == nil)
    }

    @Test("date from invalid ISO 8601 string returns nil")
    func dateFromInvalidString() {
        let result = DateService.date(fromISO8601: "not-a-date")
        #expect(result == nil)
    }
}
