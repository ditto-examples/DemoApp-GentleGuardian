import Foundation
import Observation

// MARK: - Data Source Protocol

/// Protocol defining the interface for other event data needed by LogOtherViewModel.
@MainActor
protocol LogOtherDataSource: AnyObject {
    func insert(event: OtherEvent) async throws
    func distinctNames(childId: String) async throws -> [String]
}

extension OtherEventRepository: LogOtherDataSource {}

/// ViewModel managing the "other" event logging form.
@Observable
@MainActor
final class LogOtherViewModel {

    // MARK: - Form State

    /// User-defined name for this activity.
    var name: String = ""

    /// Duration of the activity in minutes (optional).
    var durationMinutes: String = ""

    /// Free-text description.
    var eventDescription: String = ""

    /// When the activity occurred (defaults to now).
    var timestamp: Date = Date()

    // MARK: - UI State

    /// Whether a save is in progress.
    var isLoading: Bool = false

    /// Error message, if any.
    var errorMessage: String?

    /// Whether the event was saved successfully.
    var didSave: Bool = false

    /// Previously used event names for this child.
    var pastNames: [String] = []

    // MARK: - Validation

    /// The form is valid when the name is not empty after trimming.
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Parsed duration, or nil if empty/invalid.
    var durationValue: Int? {
        durationMinutes.isEmpty ? nil : Int(durationMinutes)
    }

    // MARK: - Dependencies

    private let childId: String
    private let otherEventRepository: any LogOtherDataSource

    // MARK: - Initialization

    init(childId: String, otherEventRepository: any LogOtherDataSource) {
        self.childId = childId
        self.otherEventRepository = otherEventRepository
    }

    // MARK: - Actions

    /// Loads previously used event names for the past-names picker.
    func loadPastNames() async {
        do {
            pastNames = try await otherEventRepository.distinctNames(childId: childId)
        } catch {
            // Non-fatal — the picker just won't show
            pastNames = []
        }
    }

    /// Saves the other event.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = OtherEvent(
            childId: childId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp,
            durationMinutes: durationValue,
            description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await otherEventRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save event. Please try again."
        }

        isLoading = false
    }
}
