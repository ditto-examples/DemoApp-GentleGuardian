import Foundation

/// The type of feeding event.
enum FeedingType: String, Codable, CaseIterable, Sendable {
    case bottle
    case breast
    case solid

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .bottle: "Bottle"
        case .breast: "Breast"
        case .solid: "Solid Food"
        }
    }

    /// SF Symbol name for this feeding type.
    var iconName: String {
        switch self {
        case .bottle: "baby.bottle"
        case .breast: "heart.circle"
        case .solid: "fork.knife"
        }
    }
}
