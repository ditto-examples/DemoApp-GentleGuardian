import Foundation

/// Category of a user-defined custom item (formula brand, food, medicine).
enum CustomItemCategory: String, Codable, CaseIterable, Sendable {
    case formula
    case solidFood = "solidFood"
    case medicine

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .formula: "Formula"
        case .solidFood: "Solid Food"
        case .medicine: "Medicine"
        }
    }
}
