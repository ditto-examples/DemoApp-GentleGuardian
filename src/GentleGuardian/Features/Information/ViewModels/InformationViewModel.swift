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

    // MARK: - Export State

    /// Whether an export operation is in progress.
    var isExporting: Bool = false

    /// The generated CSV document ready for the file exporter.
    var exportDocument: CSVDocument?

    /// Whether the file exporter sheet is presented.
    var showExporter: Bool = false

    /// Export error message to display, if any.
    var exportError: String?

    // MARK: - Dependencies

    private let dittoManager: any DittoManaging
    private let userSettings: UserSettings
    private let exportService: ExportService

    // MARK: - Initialization

    init(dittoManager: any DittoManaging, userSettings: UserSettings) {
        self.dittoManager = dittoManager
        self.userSettings = userSettings
        self.exportService = ExportService(dittoManager: dittoManager)

        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.sdkVersion = Ditto.version
    }

    // MARK: - Actions

    /// Generates a CSV export of all child data and triggers the file exporter.
    func exportData(child: Child) async {
        isExporting = true
        exportError = nil

        do {
            let csvString = try await exportService.generateCSV(for: child, childId: child.id)
            exportDocument = CSVDocument(csvString: csvString)
            showExporter = true
        } catch {
            exportError = "Export failed. Please try again."
        }

        isExporting = false
    }

    /// Suggested file name for the CSV export.
    func exportFileName(for child: Child) -> String {
        let dateStr = DateService.dateString(from: Date())
        let safeName = child.firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        return "gentleguardian-\(safeName)-\(dateStr).csv"
    }

    /// Starts observing the Ditto presence graph for peer changes.
    func startObservingPresence() async {
        await dittoManager.observePresence { [weak self] peers in
            Task { @MainActor in
                self?.remotePeers = peers.filter { !$0.isLocal }
            }
        }
    }
}
