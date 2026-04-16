import Foundation

/// Consistency/texture of stool in a diaper change (poop only).
enum DiaperConsistency: String, Codable, CaseIterable, Sendable {
    case solid
    case loose
    case runny
    case hard
    case pebbles
    case diarrhea

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .solid: "Solid"
        case .loose: "Loose"
        case .runny: "Runny"
        case .hard: "Hard"
        case .pebbles: "Pebbles"
        case .diarrhea: "Diarrhea"
        }
    }
}
