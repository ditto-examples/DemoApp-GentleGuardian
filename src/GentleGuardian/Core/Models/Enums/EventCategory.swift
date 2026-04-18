import Foundation

/// Top-level event categories used for UI routing and filtering.
enum EventCategory: String, Codable, CaseIterable, Sendable {
    case feeding
    case diaper
    case health
    case activity
    case sleep
    case other

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .feeding: "Feeding"
        case .diaper: "Diaper"
        case .health: "Health"
        case .activity: "Activity"
        case .sleep: "Sleep"
        case .other: "Other"
        }
    }

    /// SF Symbol name for this event category.
    var iconName: String {
        switch self {
        case .feeding: "spoon.serving"
        case .diaper: "humidity.fill"
        case .health: "heart.text.clipboard.fill"
        case .activity: "figure.play"
        case .sleep: "moon.fill"
        case .other: "pencil.and.outline"
        }
    }

    /// The Ditto collection name associated with this category.
    var collectionName: String {
        switch self {
        case .feeding: AppConstants.Collections.feeding
        case .diaper: AppConstants.Collections.diaper
        case .health: AppConstants.Collections.health
        case .activity: AppConstants.Collections.activity
        case .sleep: AppConstants.Collections.sleep
        case .other: AppConstants.Collections.otherEvents
        }
    }
}
