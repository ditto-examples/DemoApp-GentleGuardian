import Foundation

/// Represents an activity event such as bath, tummy time, or outdoor play.
struct ActivityEvent: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this event belongs to.
    var childId: String

    /// Type of activity performed.
    var activityType: ActivityType

    /// When the activity occurred.
    var timestamp: Date

    /// Date string in "YYYY-MM-DD" format for grouping by day.
    var date: String

    /// Duration of the activity in minutes, if applicable.
    var durationMinutes: Int?

    /// Free-text description of the activity.
    var description: String

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
        activityType: ActivityType,
        timestamp: Date = Date(),
        date: String? = nil,
        durationMinutes: Int? = nil,
        description: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.childId = childId
        self.activityType = activityType
        self.timestamp = timestamp
        self.date = date ?? DateService.dateString(from: timestamp)
        self.durationMinutes = durationMinutes
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.activityType = ActivityType(rawValue: document["activityType"] as? String ?? "") ?? .bath
        self.timestamp = DateService.date(fromISO8601: document["timestamp"] as? String) ?? Date()
        self.date = document["date"] as? String ?? DateService.todayString()
        self.durationMinutes = document["durationMinutes"] as? Int
        self.description = document["description"] as? String ?? ""
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
            "activityType": activityType.rawValue,
            "timestamp": DateService.iso8601String(from: timestamp),
            "date": date,
            "durationMinutes": durationMinutes,
            "description": description,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived
        ]
    }

    // MARK: - Computed Properties

    /// A human-readable summary of this activity event.
    var summary: String {
        if let mins = durationMinutes {
            return "\(activityType.displayName) - \(mins) min"
        }
        return activityType.displayName
    }
}
