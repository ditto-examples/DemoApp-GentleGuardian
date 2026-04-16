// PreviewData.swift
// GentleGuardian - Mock Data for SwiftUI Previews
//
// Uses the actual model types from Core/Models/.
// All data is static and suitable for preview rendering.

import Foundation
import SwiftUI

// MARK: - Preview Data

enum PreviewData {

    // MARK: - Date Helpers

    private static func todayAt(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: .now
        ) ?? .now
    }

    private static func yesterdayAt(hour: Int, minute: Int) -> Date {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: yesterday
        ) ?? .now
    }

    // MARK: - Children

    static let baby = Child(
        id: "child-001",
        firstName: "Theodore",
        birthday: Calendar.current.date(byAdding: .month, value: -8, to: .now)!,
        sex: .male,
        prematurityWeeks: 6,
        prematurityStatus: .earlyTerm,
        syncCode: "ABC123"
    )

    static let secondChild = Child(
        id: "child-002",
        firstName: "Liam",
        birthday: Calendar.current.date(byAdding: .month, value: -3, to: .now)!,
        sex: .male,
        syncCode: "XYZ789"
    )

    static let allChildren: [Child] = [baby, secondChild]

    // MARK: - Feeding Events

    static let bottleFeeding = FeedingEvent(
        id: "feed-001",
        childId: "child-001",
        type: .bottle,
        timestamp: todayAt(hour: 7, minute: 15),
        bottleQuantity: 8.0,
        bottleQuantityUnit: .oz,
        formulaType: "Soy Formula"
    )

    static let breastFeeding = FeedingEvent(
        id: "feed-002",
        childId: "child-001",
        type: .breast,
        timestamp: todayAt(hour: 10, minute: 30),
        breastDurationMinutes: 20,
        breastSide: .left,
        notes: "Good latch"
    )

    static let solidFeeding = FeedingEvent(
        id: "feed-003",
        childId: "child-001",
        type: .solid,
        timestamp: todayAt(hour: 12, minute: 0),
        solidType: "Sweet potato puree",
        notes: "2 tablespoons"
    )

    static let recentFeeding = FeedingEvent(
        id: "feed-004",
        childId: "child-001",
        type: .bottle,
        timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
        bottleQuantity: 6.0,
        bottleQuantityUnit: .oz
    )

    static let allFeedings: [FeedingEvent] = [
        bottleFeeding, breastFeeding, solidFeeding, recentFeeding
    ]

    // MARK: - Diaper Events

    static let wetDiaper = DiaperEvent(
        id: "diaper-001",
        childId: "child-001",
        type: .pee,
        timestamp: todayAt(hour: 9, minute: 15),
        quantity: .medium
    )

    static let dirtyDiaper = DiaperEvent(
        id: "diaper-002",
        childId: "child-001",
        type: .poop,
        timestamp: todayAt(hour: 11, minute: 45),
        quantity: .medium,
        notes: "Normal color and consistency"
    )

    static let allDiapers: [DiaperEvent] = [wetDiaper, dirtyDiaper]

    // MARK: - Health Events

    static let temperatureReading = HealthEvent(
        id: "health-001",
        childId: "child-001",
        type: .temperature,
        timestamp: todayAt(hour: 8, minute: 0),
        temperatureValue: 98.6,
        temperatureUnit: .fahrenheit,
        notes: "Normal range"
    )

    static let medicineEvent = HealthEvent(
        id: "health-002",
        childId: "child-001",
        type: .medicine,
        timestamp: todayAt(hour: 14, minute: 0),
        medicineName: "Infant Tylenol",
        medicineQuantity: 1.25,
        medicineQuantityUnit: .ml
    )

    static let allHealth: [HealthEvent] = [temperatureReading, medicineEvent]

    // MARK: - Activity Events

    static let tummyTime = ActivityEvent(
        id: "activity-001",
        childId: "child-001",
        activityType: .tummyTime,
        timestamp: todayAt(hour: 9, minute: 0),
        durationMinutes: 15
    )

    static let bathTime = ActivityEvent(
        id: "activity-002",
        childId: "child-001",
        activityType: .bath,
        timestamp: todayAt(hour: 18, minute: 30),
        durationMinutes: 20,
        description: "Loved splashing today"
    )

    static let allActivities: [ActivityEvent] = [tummyTime, bathTime]

    // MARK: - Summary Data (for Daily Summary previews)

    static let totalSleepMinutesToday: Int = 552  // 9h 12m
    static let totalFeedingsToday: Int = 4
    static let totalDiapersToday: Int = 6
    static let lastDiaperStatus: String = "Clean"
}
