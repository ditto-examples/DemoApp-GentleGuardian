import Foundation

/// The type of diaper change event.
enum DiaperType: String, Codable, CaseIterable, Sendable {
    case poop
    case pee

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .poop: "Poop"
        case .pee: "Pee"
        }
    }

    /// SF Symbol name for this diaper type.
    var iconName: String {
        switch self {
        case .poop: "circle.fill"
        case .pee: "drop.fill"
        }
    }
}
