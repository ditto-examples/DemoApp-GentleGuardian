import Foundation

/// The type of activity event being tracked.
enum ActivityType: String, Codable, CaseIterable, Sendable {
    case bath
    case tummyTime
    case storyTime
    case screenTime
    case outdoorPlay
    case indoorPlay
    case brushTeeth
    case skinToSkin

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .bath: "Bath"
        case .tummyTime: "Tummy Time"
        case .storyTime: "Story Time"
        case .screenTime: "Screen Time"
        case .outdoorPlay: "Outdoor Play"
        case .indoorPlay: "Indoor Play"
        case .brushTeeth: "Brush Teeth"
        case .skinToSkin: "Skin to Skin"
        }
    }

    /// SF Symbol name for this activity type.
    var iconName: String {
        switch self {
        case .bath: "bathtub.fill"
        case .tummyTime: "figure.rolling"
        case .storyTime: "book.fill"
        case .screenTime: "tv.fill"
        case .outdoorPlay: "sun.max.fill"
        case .indoorPlay: "puzzlepiece.fill"
        case .brushTeeth: "mouth.fill"
        case .skinToSkin: "heart.fill"
        }
    }

    /// Whether this activity typically has a duration.
    var hasDuration: Bool {
        switch self {
        case .brushTeeth: false
        default: true
        }
    }
}
