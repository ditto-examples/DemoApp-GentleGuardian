import Foundation

/// Unit of measurement for solid food quantities.
enum QuantityUnit: String, Codable, CaseIterable, Sendable {
    case tbsp
    case oz
    case g
    case pieces

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .tbsp: "tbsp"
        case .oz: "oz"
        case .g: "g"
        case .pieces: "pieces"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .tbsp: "tablespoons"
        case .oz: "ounces"
        case .g: "grams"
        case .pieces: "pieces"
        }
    }
}
