import Foundation

/// Unit of measurement for liquid volumes (bottle feeding).
enum VolumeUnit: String, Codable, CaseIterable, Sendable {
    case oz
    case ml

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .oz: "oz"
        case .ml: "mL"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .oz: "ounces"
        case .ml: "milliliters"
        }
    }
}
