import Foundation
import SwiftUI

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

    /// SwiftUI Color used to tint indicators (e.g., the home status circle)
    /// so caregivers can spot the most recent stool color at a glance.
    var displayColor: Color {
        switch self {
        case .brown: Color(red: 0.55, green: 0.35, blue: 0.20)
        case .green: Color(red: 0.30, green: 0.65, blue: 0.35)
        case .yellow: Color(red: 0.92, green: 0.78, blue: 0.30)
        case .black: Color(red: 0.18, green: 0.18, blue: 0.20)
        case .red: Color(red: 0.85, green: 0.25, blue: 0.25)
        case .white: Color(red: 0.85, green: 0.85, blue: 0.82)
        }
    }
}
