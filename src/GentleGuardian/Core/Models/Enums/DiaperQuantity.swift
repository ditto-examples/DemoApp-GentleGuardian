import Foundation

/// Qualitative amount for a diaper change.
enum DiaperQuantity: String, Codable, CaseIterable, Sendable {
    case little
    case medium
    case big

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .little: "Little"
        case .medium: "Medium"
        case .big: "Big"
        }
    }
}
