import Foundation

/// The type of health event being tracked.
enum HealthEventType: String, Codable, CaseIterable, Sendable {
    case medicine
    case temperature
    case growth

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .medicine: "Medicine"
        case .temperature: "Temperature"
        case .growth: "Growth"
        }
    }

    /// SF Symbol name for this health event type.
    var iconName: String {
        switch self {
        case .medicine: "pill.fill"
        case .temperature: "thermometer"
        case .growth: "ruler"
        }
    }
}
