import Foundation

/// Represents a single feeding event (bottle, breast, or solid food).
struct FeedingEvent: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this event belongs to.
    var childId: String

    /// Type of feeding: bottle, breast, or solid.
    var type: FeedingType

    /// When the feeding occurred.
    var timestamp: Date

    /// Date string in "YYYY-MM-DD" format for grouping by day.
    var date: String

    // MARK: - Bottle Fields

    /// Amount of liquid consumed (bottle feeding).
    var bottleQuantity: Double?

    /// Unit of measurement for bottle quantity.
    var bottleQuantityUnit: VolumeUnit?

    /// Type/brand of formula used, if applicable.
    var formulaType: String?

    // MARK: - Breast Fields

    /// Duration of breastfeeding session in minutes.
    var breastDurationMinutes: Int?

    /// Which breast was used.
    var breastSide: BreastSide?

    // MARK: - Solid Fields

    /// Name/type of solid food.
    var solidType: String?

    /// Quantity of solid food consumed.
    var solidQuantity: Double?

    /// Unit of measurement for solid food quantity.
    var solidQuantityUnit: QuantityUnit?

    // MARK: - Common Fields

    /// Optional notes about this feeding.
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
        type: FeedingType,
        timestamp: Date = Date(),
        date: String? = nil,
        bottleQuantity: Double? = nil,
        bottleQuantityUnit: VolumeUnit? = nil,
        formulaType: String? = nil,
        breastDurationMinutes: Int? = nil,
        breastSide: BreastSide? = nil,
        solidType: String? = nil,
        solidQuantity: Double? = nil,
        solidQuantityUnit: QuantityUnit? = nil,
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
        self.bottleQuantity = bottleQuantity
        self.bottleQuantityUnit = bottleQuantityUnit
        self.formulaType = formulaType
        self.breastDurationMinutes = breastDurationMinutes
        self.breastSide = breastSide
        self.solidType = solidType
        self.solidQuantity = solidQuantity
        self.solidQuantityUnit = solidQuantityUnit
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.type = FeedingType(rawValue: document["type"] as? String ?? "") ?? .bottle
        self.timestamp = DateService.date(fromISO8601: document["timestamp"] as? String) ?? Date()
        self.date = document["date"] as? String ?? DateService.todayString()
        self.bottleQuantity = document["bottleQuantity"] as? Double
        if let unitStr = document["bottleQuantityUnit"] as? String {
            self.bottleQuantityUnit = VolumeUnit(rawValue: unitStr)
        } else {
            self.bottleQuantityUnit = nil
        }
        self.formulaType = document["formulaType"] as? String
        self.breastDurationMinutes = document["breastDurationMinutes"] as? Int
        if let sideStr = document["breastSide"] as? String {
            self.breastSide = BreastSide(rawValue: sideStr)
        } else {
            self.breastSide = nil
        }
        self.solidType = document["solidType"] as? String
        self.solidQuantity = document["solidQuantity"] as? Double
        if let unitStr = document["solidQuantityUnit"] as? String {
            self.solidQuantityUnit = QuantityUnit(rawValue: unitStr)
        } else {
            self.solidQuantityUnit = nil
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
            "bottleQuantity": bottleQuantity,
            "bottleQuantityUnit": bottleQuantityUnit?.rawValue,
            "formulaType": formulaType,
            "breastDurationMinutes": breastDurationMinutes,
            "breastSide": breastSide?.rawValue,
            "solidType": solidType,
            "solidQuantity": solidQuantity,
            "solidQuantityUnit": solidQuantityUnit?.rawValue,
            "notes": notes,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived
        ]
    }

    // MARK: - Computed Properties

    /// A human-readable summary of this feeding event.
    var summary: String {
        switch type {
        case .bottle:
            if let qty = bottleQuantity, let unit = bottleQuantityUnit {
                let formulaInfo = formulaType.map { " (\($0))" } ?? ""
                return "\(qty) \(unit.displayName)\(formulaInfo)"
            }
            return "Bottle"
        case .breast:
            let sideInfo = breastSide?.displayName ?? ""
            if let mins = breastDurationMinutes {
                return "\(mins) min \(sideInfo)".trimmingCharacters(in: .whitespaces)
            }
            return "Breast \(sideInfo)".trimmingCharacters(in: .whitespaces)
        case .solid:
            if let food = solidType {
                if let qty = solidQuantity, let unit = solidQuantityUnit {
                    return "\(food) - \(qty) \(unit.displayName)"
                }
                return food
            }
            return "Solid food"
        }
    }
}
