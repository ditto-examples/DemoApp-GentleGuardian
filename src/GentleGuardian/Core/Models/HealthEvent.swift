import Foundation

/// Represents a health-related event: medicine, temperature, or growth measurement.
struct HealthEvent: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this event belongs to.
    var childId: String

    /// Type of health event: medicine, temperature, or growth.
    var type: HealthEventType

    /// When this health event occurred.
    var timestamp: Date

    /// Date string in "YYYY-MM-DD" format for grouping by day.
    var date: String

    // MARK: - Medicine Fields

    /// Name of the medicine administered.
    var medicineName: String?

    /// Dosage quantity.
    var medicineQuantity: Double?

    /// Unit of dosage measurement.
    var medicineQuantityUnit: MedicineUnit?

    // MARK: - Temperature Fields

    /// Temperature reading value.
    var temperatureValue: Double?

    /// Unit of temperature measurement.
    var temperatureUnit: TemperatureUnit?

    // MARK: - Growth Fields

    /// Height/length measurement value.
    var heightValue: Double?

    /// Unit of height measurement.
    var heightUnit: HeightUnit?

    /// Weight measurement value.
    var weightValue: Double?

    /// Unit of weight measurement.
    var weightUnit: WeightUnit?

    // MARK: - Common Fields

    /// Optional notes about this health event.
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
        type: HealthEventType,
        timestamp: Date = Date(),
        date: String? = nil,
        medicineName: String? = nil,
        medicineQuantity: Double? = nil,
        medicineQuantityUnit: MedicineUnit? = nil,
        temperatureValue: Double? = nil,
        temperatureUnit: TemperatureUnit? = nil,
        heightValue: Double? = nil,
        heightUnit: HeightUnit? = nil,
        weightValue: Double? = nil,
        weightUnit: WeightUnit? = nil,
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
        self.medicineName = medicineName
        self.medicineQuantity = medicineQuantity
        self.medicineQuantityUnit = medicineQuantityUnit
        self.temperatureValue = temperatureValue
        self.temperatureUnit = temperatureUnit
        self.heightValue = heightValue
        self.heightUnit = heightUnit
        self.weightValue = weightValue
        self.weightUnit = weightUnit
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.type = HealthEventType(rawValue: document["type"] as? String ?? "") ?? .medicine
        self.timestamp = DateService.date(fromISO8601: document["timestamp"] as? String) ?? Date()
        self.date = document["date"] as? String ?? DateService.todayString()

        // Medicine fields
        self.medicineName = document["medicineName"] as? String
        self.medicineQuantity = document["medicineQuantity"] as? Double
        if let unitStr = document["medicineQuantityUnit"] as? String {
            self.medicineQuantityUnit = MedicineUnit(rawValue: unitStr)
        } else {
            self.medicineQuantityUnit = nil
        }

        // Temperature fields
        self.temperatureValue = document["temperatureValue"] as? Double
        if let unitStr = document["temperatureUnit"] as? String {
            self.temperatureUnit = TemperatureUnit(rawValue: unitStr)
        } else {
            self.temperatureUnit = nil
        }

        // Growth fields
        self.heightValue = document["heightValue"] as? Double
        if let unitStr = document["heightUnit"] as? String {
            self.heightUnit = HeightUnit(rawValue: unitStr)
        } else {
            self.heightUnit = nil
        }
        self.weightValue = document["weightValue"] as? Double
        if let unitStr = document["weightUnit"] as? String {
            self.weightUnit = WeightUnit(rawValue: unitStr)
        } else {
            self.weightUnit = nil
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
            "medicineName": medicineName,
            "medicineQuantity": medicineQuantity,
            "medicineQuantityUnit": medicineQuantityUnit?.rawValue,
            "temperatureValue": temperatureValue,
            "temperatureUnit": temperatureUnit?.rawValue,
            "heightValue": heightValue,
            "heightUnit": heightUnit?.rawValue,
            "weightValue": weightValue,
            "weightUnit": weightUnit?.rawValue,
            "notes": notes,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived
        ]
    }

    // MARK: - Computed Properties

    /// A human-readable summary of this health event.
    var summary: String {
        switch type {
        case .medicine:
            if let name = medicineName {
                if let qty = medicineQuantity, let unit = medicineQuantityUnit {
                    return "\(name) - \(qty) \(unit.displayName)"
                }
                return name
            }
            return "Medicine"
        case .temperature:
            if let value = temperatureValue, let unit = temperatureUnit {
                return "\(String(format: "%.1f", value))\(unit.displayName)"
            }
            return "Temperature"
        case .growth:
            var parts: [String] = []
            if let h = heightValue, let hu = heightUnit {
                parts.append("\(String(format: "%.1f", h)) \(hu.displayName)")
            }
            if let w = weightValue, let wu = weightUnit {
                parts.append("\(String(format: "%.1f", w)) \(wu.displayName)")
            }
            return parts.isEmpty ? "Growth" : parts.joined(separator: ", ")
        }
    }
}
