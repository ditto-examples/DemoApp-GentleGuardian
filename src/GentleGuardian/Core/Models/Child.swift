import Foundation

/// Represents a child being tracked in the app.
///
/// Each child has a unique sync code that allows other devices to subscribe
/// to their data for collaborative caregiving.
struct Child: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// Child's first name.
    var firstName: String

    /// Child's date of birth.
    var birthday: Date

    /// Biological sex of the child.
    var sex: Sex

    /// Number of weeks premature, if applicable.
    var prematurityWeeks: Int?

    /// Classification of prematurity status, if applicable.
    var prematurityStatus: PrematurityStatus?

    /// 6-character alphanumeric code used for syncing between devices.
    var syncCode: String

    /// Hour of day (0-23) when the tracking day starts.
    var dayStartHour: Int

    /// Hour of day (0-23) when the tracking day ends.
    var dayEndHour: Int

    /// Timestamp when this record was created.
    var createdAt: Date

    /// Timestamp when this record was last modified.
    var updatedAt: Date

    /// Soft-delete flag. Archived children are hidden from the UI.
    var isArchived: Bool

    /// The device ID that originally created this child record.
    var createdByDeviceId: String

    // MARK: - Initialization

    /// Creates a new Child with default values.
    init(
        id: String = UUID().uuidString,
        firstName: String,
        birthday: Date,
        sex: Sex,
        prematurityWeeks: Int? = nil,
        prematurityStatus: PrematurityStatus? = nil,
        syncCode: String,
        dayStartHour: Int = AppConstants.defaultDayStartHour,
        dayEndHour: Int = AppConstants.defaultDayEndHour,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        createdByDeviceId: String = ""
    ) {
        self.id = id
        self.firstName = firstName
        self.birthday = birthday
        self.sex = sex
        self.prematurityWeeks = prematurityWeeks
        self.prematurityStatus = prematurityStatus
        self.syncCode = syncCode
        self.dayStartHour = dayStartHour
        self.dayEndHour = dayEndHour
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.createdByDeviceId = createdByDeviceId
    }

    /// Initializes a Child from a Ditto document dictionary.
    ///
    /// - Parameter document: A dictionary of key-value pairs from a Ditto query result item.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.firstName = document["firstName"] as? String ?? ""
        self.birthday = DateService.date(fromISO8601: document["birthday"] as? String) ?? Date()
        self.sex = Sex(rawValue: document["sex"] as? String ?? "") ?? .other
        self.prematurityWeeks = document["prematurityWeeks"] as? Int
        if let statusStr = document["prematurityStatus"] as? String {
            self.prematurityStatus = PrematurityStatus(rawValue: statusStr)
        } else {
            self.prematurityStatus = nil
        }
        self.syncCode = document["syncCode"] as? String ?? ""
        self.dayStartHour = document["dayStartHour"] as? Int ?? AppConstants.defaultDayStartHour
        self.dayEndHour = document["dayEndHour"] as? Int ?? AppConstants.defaultDayEndHour
        self.createdAt = DateService.date(fromISO8601: document["createdAt"] as? String) ?? Date()
        self.updatedAt = DateService.date(fromISO8601: document["updatedAt"] as? String) ?? Date()
        self.isArchived = document["isArchived"] as? Bool ?? false
        self.createdByDeviceId = document["createdByDeviceId"] as? String ?? ""
    }

    // MARK: - Serialization

    /// Converts this Child to a dictionary suitable for Ditto INSERT.
    func toDittoDocument() -> [String: Any?] {
        [
            "_id": id,
            "firstName": firstName,
            "birthday": DateService.iso8601String(from: birthday),
            "sex": sex.rawValue,
            "prematurityWeeks": prematurityWeeks,
            "prematurityStatus": prematurityStatus?.rawValue,
            "syncCode": syncCode,
            "dayStartHour": dayStartHour,
            "dayEndHour": dayEndHour,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived,
            "createdByDeviceId": createdByDeviceId
        ]
    }

    // MARK: - Computed Properties

    /// The child's age as a human-readable string.
    var ageString: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthday, to: Date())

        if let years = components.year, years > 0 {
            if let months = components.month, months > 0 {
                return "\(years)y \(months)m"
            }
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            if let days = components.day, days > 0 {
                return "\(months)m \(days)d"
            }
            return "\(months)m"
        } else if let days = components.day {
            return "\(max(days, 0))d"
        }
        return "0d"
    }
}
