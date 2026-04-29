import Foundation
import SwiftUI

/// Caregiver-recorded reaction to a solid feeding so families can spot foods
/// the baby dislikes and avoid re-buying them.
enum SolidReaction: String, Codable, CaseIterable, Sendable {
    case happy
    case neutral
    case frown

    /// Human-readable label.
    var displayName: String {
        switch self {
        case .happy: "Liked it"
        case .neutral: "So-so"
        case .frown: "Disliked"
        }
    }

    /// Emoji used to render the reaction. SF Symbols lacks a reliable frown
    /// face across all targeted OS versions, so emoji are used to keep the
    /// three reactions visually consistent.
    var emoji: String {
        switch self {
        case .happy: "😀"
        case .neutral: "😐"
        case .frown: "🙁"
        }
    }

    /// Tint color used for emphasis (e.g., bordering the selected option).
    var tintColor: Color {
        switch self {
        case .happy: Color(red: 0.30, green: 0.65, blue: 0.35)
        case .neutral: Color(red: 0.85, green: 0.70, blue: 0.30)
        case .frown: Color(red: 0.85, green: 0.30, blue: 0.30)
        }
    }
}
