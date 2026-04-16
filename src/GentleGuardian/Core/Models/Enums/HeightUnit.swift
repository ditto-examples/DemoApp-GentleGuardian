import Foundation

/// Unit of measurement for height/length.
enum HeightUnit: String, Codable, CaseIterable, Sendable {
    case inches
    case feet
    case cm
    case m

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .inches: "in"
        case .feet: "ft"
        case .cm: "cm"
        case .m: "m"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .inches: "inches"
        case .feet: "feet"
        case .cm: "centimeters"
        case .m: "meters"
        }
    }
}
