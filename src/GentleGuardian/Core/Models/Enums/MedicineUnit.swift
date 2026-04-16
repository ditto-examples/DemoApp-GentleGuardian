import Foundation

/// Unit of measurement for medicine dosage.
enum MedicineUnit: String, Codable, CaseIterable, Sendable {
    case ml
    case tsp
    case tbsp
    case drops
    case mg

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .ml: "mL"
        case .tsp: "tsp"
        case .tbsp: "tbsp"
        case .drops: "drops"
        case .mg: "mg"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .ml: "milliliters"
        case .tsp: "teaspoons"
        case .tbsp: "tablespoons"
        case .drops: "drops"
        case .mg: "milligrams"
        }
    }
}
