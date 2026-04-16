import Foundation

/// Unit of measurement for weight.
enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case g
    case kg
    case oz
    case lb

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .g: "g"
        case .kg: "kg"
        case .oz: "oz"
        case .lb: "lb"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .g: "grams"
        case .kg: "kilograms"
        case .oz: "ounces"
        case .lb: "pounds"
        }
    }
}
