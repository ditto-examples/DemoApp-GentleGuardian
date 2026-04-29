import Foundation
import Observation

// MARK: - Data Source Protocol

/// Protocol defining the interface for other event data needed by LogOtherViewModel.
@MainActor
protocol LogOtherDataSource: AnyObject {
    func insert(event: OtherEvent) async throws
    func update(event: OtherEvent) async throws
    func softDelete(eventId: String) async throws
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

    /// Whether a delete just succeeded.
    var didDelete: Bool = false

    /// Previously used event names for this child.
    var pastNames: [String] = []

    // MARK: - Edit Mode

    private(set) var existingEventId: String?

    var isEditing: Bool { existingEventId != nil }

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

    /// Edit flow — pre-fills every field from the source event.
    init(existingEvent: OtherEvent, otherEventRepository: any LogOtherDataSource) {
        self.childId = existingEvent.childId
        self.otherEventRepository = otherEventRepository
        self.existingEventId = existingEvent.id
        self.name = existingEvent.name
        self.timestamp = existingEvent.timestamp
        if let dur = existingEvent.durationMinutes {
            self.durationMinutes = String(dur)
        }
        self.eventDescription = existingEvent.description
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

    /// Saves the other event — inserts when creating, updates when editing.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = OtherEvent(
            id: existingEventId ?? UUID().uuidString,
            childId: childId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp,
            durationMinutes: durationValue,
            description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            if isEditing {
                try await otherEventRepository.update(event: event)
            } else {
                try await otherEventRepository.insert(event: event)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save event. Please try again."
        }

        isLoading = false
    }

    /// Soft-deletes the event currently being edited.
    func delete() async {
        guard let id = existingEventId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await otherEventRepository.softDelete(eventId: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete event. Please try again."
        }

        isLoading = false
    }
}
