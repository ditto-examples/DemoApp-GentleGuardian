import Foundation

/// Unit of measurement for temperature readings.
enum TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case fahrenheit
    case celsius

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .fahrenheit: "\u{00B0}F"
        case .celsius: "\u{00B0}C"
        }
    }

    /// Full unit name for accessibility.
    var fullName: String {
        switch self {
        case .fahrenheit: "Fahrenheit"
        case .celsius: "Celsius"
        }
    }

    /// Convert a value from this unit to the other.
    func convert(_ value: Double, to target: TemperatureUnit) -> Double {
        guard self != target else { return value }
        switch (self, target) {
        case (.fahrenheit, .celsius):
            return (value - 32.0) * 5.0 / 9.0
        case (.celsius, .fahrenheit):
            return value * 9.0 / 5.0 + 32.0
        default:
            return value
        }
    }
}
