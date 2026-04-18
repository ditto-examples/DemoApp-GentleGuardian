import Foundation

/// Represents a sleep event with start time, end time, and pre-calculated duration.
struct SleepEvent: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this event belongs to.
    var childId: String

    /// When sleep began.
    var startTime: Date

    /// When sleep ended.
    var endTime: Date

    /// Pre-calculated duration in minutes (endTime - startTime).
    var durationMinutes: Int

    /// When the event occurred, set to startTime for chronological sorting.
    var timestamp: Date

    /// Date string in "YYYY-MM-DD" format for grouping by day.
    var date: String

    /// Optional notes about this sleep session.
    var notes: String

    /// Timestamp when this record was created.
    var createdAt: Date

    /// Timestamp when this record was last modified.
    var updatedAt: Date

    /// Soft-delete flag.
    var isArchived: Bool

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        childId: String,
        startTime: Date,
        endTime: Date,
        durationMinutes: Int? = nil,
        timestamp: Date? = nil,
        date: String? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.childId = childId
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes ?? max(0, Int(endTime.timeIntervalSince(startTime) / 60))
        self.timestamp = timestamp ?? startTime
        self.date = date ?? DateService.dateString(from: startTime)
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.startTime = DateService.date(fromISO8601: document["startTime"] as? String) ?? Date()
        self.endTime = DateService.date(fromISO8601: document["endTime"] as? String) ?? Date()
        self.durationMinutes = document["durationMinutes"] as? Int ?? 0
        self.timestamp = DateService.date(fromISO8601: document["timestamp"] as? String) ?? Date()
        self.date = document["date"] as? String ?? DateService.todayString()
        self.notes = document["notes"] as? String ?? ""
        self.createdAt = DateService.date(fromISO8601: document["createdAt"] as? String) ?? Date()
        self.updatedAt = DateService.date(fromISO8601: document["updatedAt"] as? String) ?? Date()
        self.isArchived = document["isArchived"] as? Bool ?? false
    }

    // MARK: - Serialization

    /// Converts this event to a dictionary suitable for Ditto INSERT.
    func toDittoDocument() -> [String: Any?] {
        [
            "_id": id,
            "childId": childId,
            "startTime": DateService.iso8601String(from: startTime),
            "endTime": DateService.iso8601String(from: endTime),
            "durationMinutes": durationMinutes,
            "timestamp": DateService.iso8601String(from: timestamp),
            "date": date,
            "notes": notes,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived
        ]
    }

    // MARK: - Computed Properties

    /// A human-readable summary of this sleep event.
    var summary: String {
        if durationMinutes >= 60 {
            let hours = durationMinutes / 60
            let minutes = durationMinutes % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(durationMinutes)m"
    }
}
