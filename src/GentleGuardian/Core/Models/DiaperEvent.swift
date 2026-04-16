import Foundation

/// Represents a single diaper change event.
struct DiaperEvent: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this event belongs to.
    var childId: String

    /// Type of diaper change: poop or pee.
    var type: DiaperType

    /// When the diaper change occurred.
    var timestamp: Date

    /// Date string in "YYYY-MM-DD" format for grouping by day.
    var date: String

    /// Qualitative amount: little, medium, or big.
    var quantity: DiaperQuantity

    /// Color of stool (poop only, nil for pee).
    var color: DiaperColor?

    /// Consistency of stool (poop only, nil for pee).
    var consistency: DiaperConsistency?

    /// Optional notes about this diaper change.
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
        type: DiaperType,
        timestamp: Date = Date(),
        date: String? = nil,
        quantity: DiaperQuantity = .medium,
        color: DiaperColor? = nil,
        consistency: DiaperConsistency? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.childId = childId
        self.type = type
        self.timestamp = timestamp
        self.date = date ?? DateService.dateString(from: timestamp)
        self.quantity = quantity
        self.color = color
        self.consistency = consistency
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.type = DiaperType(rawValue: document["type"] as? String ?? "") ?? .pee
        self.timestamp = DateService.date(fromISO8601: document["timestamp"] as? String) ?? Date()
        self.date = document["date"] as? String ?? DateService.todayString()
        self.quantity = DiaperQuantity(rawValue: document["quantity"] as? String ?? "") ?? .medium
        if let colorStr = document["color"] as? String {
            self.color = DiaperColor(rawValue: colorStr)
        } else {
            self.color = nil
        }
        if let consistencyStr = document["consistency"] as? String {
            self.consistency = DiaperConsistency(rawValue: consistencyStr)
        } else {
            self.consistency = nil
        }
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
            "type": type.rawValue,
            "timestamp": DateService.iso8601String(from: timestamp),
            "date": date,
            "quantity": quantity.rawValue,
            "color": color?.rawValue,
            "consistency": consistency?.rawValue,
            "notes": notes,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived
        ]
    }

    // MARK: - Computed Properties

    /// A human-readable summary of this diaper event.
    var summary: String {
        var parts: [String] = [type.displayName, quantity.displayName]
        if let color = color {
            parts.append(color.displayName)
        }
        if let consistency = consistency {
            parts.append(consistency.displayName)
        }
        return parts.joined(separator: " - ")
    }
}
