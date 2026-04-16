import Foundation

/// Which breast was used during a breastfeeding session.
enum BreastSide: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case both

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        case .both: "Both"
        }
    }
}
