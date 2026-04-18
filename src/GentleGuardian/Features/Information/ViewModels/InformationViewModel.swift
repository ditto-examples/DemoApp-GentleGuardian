import Foundation
import Observation
import DittoSwift

/// ViewModel for the Information tab.
///
/// Provides app metadata, peer presence observation, and controls
/// for the privacy/legal sheet presentation state.
@Observable
@MainActor
final class InformationViewModel {

    // MARK: - App Info

    /// The app's marketing version (CFBundleShortVersionString).
    let appVersion: String

    /// The Ditto SDK version string.
    let sdkVersion: String

    // MARK: - Peer State

    /// The current user's display name from UserSettings.
    var displayName: String {
        userSettings.displayName
    }

    /// All remote peers currently visible in the mesh.
    var remotePeers: [PeerInfo] = []

    // MARK: - Sheet State

    /// Controls presentation of the privacy notice sheet.
    var showPrivacyNotice: Bool = false

    /// Controls presentation of the legal information sheet.
    var showLegalInfo: Bool = false

    // MARK: - Dependencies

    private let dittoManager: any DittoManaging
    private let userSettings: UserSettings

    // MARK: - Initialization

    init(dittoManager: any DittoManaging, userSettings: UserSettings) {
        self.dittoManager = dittoManager
        self.userSettings = userSettings

        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.sdkVersion = Ditto.version
    }

    // MARK: - Actions

    /// Starts observing the Ditto presence graph for peer changes.
    func startObservingPresence() async {
        await dittoManager.observePresence { [weak self] peers in
            Task { @MainActor in
                self?.remotePeers = peers.filter { !$0.isLocal }
            }
        }
    }
}
