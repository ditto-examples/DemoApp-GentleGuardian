import Foundation

/// Color of stool in a diaper change (poop only).
enum DiaperColor: String, Codable, CaseIterable, Sendable {
    case brown
    case green
    case yellow
    case black
    case red
    case white

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .brown: "Brown"
        case .green: "Green"
        case .yellow: "Yellow"
        case .black: "Black"
        case .red: "Red"
        case .white: "White"
        }
    }

    /// Whether this color may warrant medical attention.
    var isAlertColor: Bool {
        switch self {
        case .black, .red, .white: true
        default: false
        }
    }
}
