import Foundation

/// A single vaccination record synced via Ditto.
struct VaccinationRecord: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this record belongs to.
    var childId: String

    /// Raw string matching a `VaccineType` raw value (e.g. "dtap", "mmr", "other").
    var vaccineType: String

    /// Dose number within a multi-dose series (0 = single-dose or unspecified).
    var doseNumber: Int

    /// When the vaccine was administered.
    var dateAdministered: Date

    /// Optional notes about this vaccination (reactions, clinic, etc.).
    var notes: String?

    /// Custom vaccine name used when `vaccineType == "other"`.
    var customVaccineName: String?

    /// Custom description used when `vaccineType == "other"`.
    var customVaccineDescription: String?

    /// Timestamp when this record was created.
    var createdAt: Date

    /// Timestamp when this record was last modified.
    var updatedAt: Date

    /// Soft-delete flag.
    var isArchived: Bool

    /// Device ID of the peer that created this record.
    var createdByDeviceId: String

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        childId: String,
        vaccineType: String,
        doseNumber: Int,
        dateAdministered: Date,
        notes: String? = nil,
        customVaccineName: String? = nil,
        customVaccineDescription: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        createdByDeviceId: String = ""
    ) {
        self.id = id
        self.childId = childId
        self.vaccineType = vaccineType
        self.doseNumber = doseNumber
        self.dateAdministered = dateAdministered
        self.notes = notes
        self.customVaccineName = customVaccineName
        self.customVaccineDescription = customVaccineDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.createdByDeviceId = createdByDeviceId
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.vaccineType = document["vaccineType"] as? String ?? ""
        self.doseNumber = document["doseNumber"] as? Int ?? 0
        self.dateAdministered = DateService.date(fromISO8601: document["dateAdministered"] as? String) ?? Date()
        self.notes = document["notes"] as? String
        self.customVaccineName = document["customVaccineName"] as? String
        self.customVaccineDescription = document["customVaccineDescription"] as? String
        self.createdAt = DateService.date(fromISO8601: document["createdAt"] as? String) ?? Date()
        self.updatedAt = DateService.date(fromISO8601: document["updatedAt"] as? String) ?? Date()
        self.isArchived = document["isArchived"] as? Bool ?? false
        self.createdByDeviceId = document["createdByDeviceId"] as? String ?? ""
    }

    // MARK: - Serialization

    /// Converts this record to a dictionary suitable for Ditto INSERT.
    func toDittoDocument() -> [String: Any?] {
        [
            "_id": id,
            "childId": childId,
            "vaccineType": vaccineType,
            "doseNumber": doseNumber,
            "dateAdministered": DateService.iso8601String(from: dateAdministered),
            "notes": notes,
            "customVaccineName": customVaccineName,
            "customVaccineDescription": customVaccineDescription,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived,
            "createdByDeviceId": createdByDeviceId
        ]
    }

    // MARK: - Computed Properties

    /// Resolves `vaccineType` to a typed `VaccineType` enum value, if recognized.
    var resolvedVaccineType: VaccineType? {
        VaccineType(rawValue: vaccineType)
    }

    /// Human-readable name for display. Falls back to `customVaccineName` for `.other`.
    var displayName: String {
        if vaccineType == VaccineType.other.rawValue {
            return customVaccineName ?? "Other Vaccine"
        }
        return resolvedVaccineType?.displayName ?? vaccineType
    }
}
