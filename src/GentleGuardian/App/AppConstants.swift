import Foundation

/// Central configuration constants for the Gentle Guardian app.
enum AppConstants {

    // MARK: - Ditto Configuration (loaded from ditto.plist)

    private static let dittoConfig: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "ditto", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            fatalError("Missing ditto.plist — copy ditto.plist.example to ditto.plist and fill in your credentials.")
        }
        return plist
    }()

    /// Ditto database ID from ditto.plist.
    static var dittoDatabaseID: String {
        guard let value = dittoConfig["DatabaseID"] as? String, !value.isEmpty, value != "YOUR_DATABASE_ID" else {
            fatalError("ditto.plist: 'DatabaseID' is missing or still set to the placeholder value.")
        }
        return value
    }

    /// Ditto playground token from ditto.plist.
    static var dittoPlaygroundToken: String {
        guard let value = dittoConfig["PlaygroundToken"] as? String, !value.isEmpty, value != "YOUR_PLAYGROUND_TOKEN" else {
            fatalError("ditto.plist: 'PlaygroundToken' is missing or still set to the placeholder value.")
        }
        return value
    }

    /// Ditto server URL from ditto.plist.
    static var dittoServerURL: String {
        if let value = dittoConfig["ServerURL"] as? String, !value.isEmpty {
            return value
        }
        return "https://\(dittoDatabaseID).cloud.ditto.live"
    }

    /// Returns true if ditto.plist is missing or still has placeholder values.
    /// Safe to call without triggering fatalError — used by integration tests.
    static var hasPlaceholderCredentials: Bool {
        guard let url = Bundle.main.url(forResource: "ditto", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return true
        }
        let dbID = plist["DatabaseID"] as? String ?? ""
        let token = plist["PlaygroundToken"] as? String ?? ""
        return dbID.isEmpty || dbID == "YOUR_DATABASE_ID"
            || token.isEmpty || token == "YOUR_PLAYGROUND_TOKEN"
    }

    // MARK: - Collection Names

    /// DQL collection names used throughout the app.
    enum Collections {
        static let children = "children"
        static let feeding = "feeding"
        static let diaper = "diaper"
        static let health = "health"
        static let activity = "activity"
        static let customItems = "customItems"

        /// All collection names for bulk operations like sync scope configuration.
        static let all: [String] = [
            children, feeding, diaper, health, activity, customItems
        ]
    }

    // MARK: - Sync Code

    /// Length of the alphanumeric sync code used for pairing devices.
    static let syncCodeLength = 6

    /// Characters allowed in sync codes (uppercase alphanumeric, excluding ambiguous chars).
    static let syncCodeCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    // MARK: - Defaults

    /// Default hour the tracking day starts (6 AM).
    static let defaultDayStartHour = 6

    /// Default hour the tracking day ends (6 AM next day, i.e., 30 = 6 AM).
    static let defaultDayEndHour = 6

    // MARK: - Limits

    /// Maximum number of children a single device can track.
    static let maxChildren = 10

    /// Maximum length for notes fields.
    static let maxNotesLength = 500
}
