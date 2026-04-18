import Foundation
import Observation

/// Observable state container for the current caregiver's identity.
///
/// Persists the caregiver's display name to UserDefaults so it survives
/// app restarts. The display name is broadcast as Ditto peer metadata
/// so other devices can identify this user in the mesh network.
@Observable
final class UserSettings: @unchecked Sendable {

    // MARK: - Properties

    /// The caregiver's display name, shown to other peers in the mesh network.
    var displayName: String {
        didSet {
            userDefaults.set(displayName, forKey: Self.displayNameKey)
        }
    }

    // MARK: - Constants

    private static let displayNameKey = "caregiverDisplayName"
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.displayName = userDefaults.string(forKey: Self.displayNameKey) ?? ""
    }
}
