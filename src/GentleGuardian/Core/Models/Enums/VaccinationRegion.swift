import Foundation

/// Supported vaccination schedule regions.
enum VaccinationRegion: String, Codable, CaseIterable, Sendable {
    case usa
    case europe

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .usa: "USA"
        case .europe: "Europe"
        }
    }

    /// Countries available in this region, as (code, displayName) pairs.
    var countries: [(code: String, name: String)] {
        switch self {
        case .usa:
            return [("US", "United States")]
        case .europe:
            return [
                ("AT", "Austria"), ("BE", "Belgium"), ("BG", "Bulgaria"),
                ("HR", "Croatia"), ("CY", "Cyprus"), ("CZ", "Czechia"),
                ("DK", "Denmark"), ("EE", "Estonia"), ("FI", "Finland"),
                ("FR", "France"), ("DE", "Germany"), ("GR", "Greece"),
                ("HU", "Hungary"), ("IS", "Iceland"), ("IE", "Ireland"),
                ("IT", "Italy"), ("LI", "Liechtenstein"), ("LT", "Lithuania"),
                ("LU", "Luxembourg"), ("LV", "Latvia"), ("MT", "Malta"),
                ("NL", "Netherlands"), ("NO", "Norway"), ("PL", "Poland"),
                ("PT", "Portugal"), ("RO", "Romania"), ("SK", "Slovakia"),
                ("SI", "Slovenia"), ("ES", "Spain"), ("SE", "Sweden")
            ]
        }
    }

    /// Flag emoji for a country code.
    static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }
}
