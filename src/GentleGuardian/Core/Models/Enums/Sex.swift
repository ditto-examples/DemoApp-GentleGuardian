import Foundation

/// Biological sex of a child, used for growth chart references.
enum Sex: String, Codable, CaseIterable, Sendable {
    case male
    case female
    case other

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }
}
