import Foundation

/// A user-defined item that can be quickly selected during event logging.
///
/// Examples: a specific formula brand, a favorite solid food, or a medicine name.
/// Custom items are scoped to a child and category.
struct CustomItem: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this custom item belongs to.
    var childId: String

    /// Category this item belongs to: formula, solidFood, or medicine.
    var category: CustomItemCategory

    /// Display name for this item (e.g., "Similac Pro-Advance", "Tylenol Infant").
    var name: String

    /// Default quantity to pre-fill when selecting this item.
    var defaultQuantity: Double?

    /// Default unit string to pre-fill (raw value of the appropriate unit enum).
    var defaultQuantityUnit: String?

    /// Timestamp when this record was created.
    var createdAt: Date

    /// Soft-delete flag.
    var isArchived: Bool

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        childId: String,
        category: CustomItemCategory,
        name: String,
        defaultQuantity: Double? = nil,
        defaultQuantityUnit: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.childId = childId
        self.category = category
        self.name = name
        self.defaultQuantity = defaultQuantity
        self.defaultQuantityUnit = defaultQuantityUnit
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.category = CustomItemCategory(rawValue: document["category"] as? String ?? "") ?? .formula
        self.name = document["name"] as? String ?? ""
        self.defaultQuantity = document["defaultQuantity"] as? Double
        self.defaultQuantityUnit = document["defaultQuantityUnit"] as? String
        self.createdAt = DateService.date(fromISO8601: document["createdAt"] as? String) ?? Date()
        self.isArchived = document["isArchived"] as? Bool ?? false
    }

    // MARK: - Serialization

    /// Converts this item to a dictionary suitable for Ditto INSERT.
    func toDittoDocument() -> [String: Any?] {
        [
            "_id": id,
            "childId": childId,
            "category": category.rawValue,
            "name": name,
            "defaultQuantity": defaultQuantity,
            "defaultQuantityUnit": defaultQuantityUnit,
            "createdAt": DateService.iso8601String(from: createdAt),
            "isArchived": isArchived
        ]
    }
}
