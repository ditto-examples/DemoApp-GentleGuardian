import Foundation
import Observation

/// ViewModel managing the activity event logging form.
@Observable
@MainActor
final class LogActivityViewModel {

    // MARK: - Form State

    /// The type of activity being logged.
    var activityType: ActivityType = .bath

    /// Duration of the activity in minutes (optional).
    var durationMinutes: String = ""

    /// Free-text description.
    var activityDescription: String = ""

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

    // MARK: - Edit Mode

    private(set) var existingEventId: String?

    var isEditing: Bool { existingEventId != nil }

    // MARK: - Validation

    /// The form is always valid since activity type has a default.
    var isFormValid: Bool {
        true
    }

    /// Parsed duration, or nil if empty/invalid.
    var durationValue: Int? {
        durationMinutes.isEmpty ? nil : Int(durationMinutes)
    }

    // MARK: - Dependencies

    private let childId: String
    private let activityRepository: ActivityRepository

    // MARK: - Initialization

    init(childId: String, activityRepository: ActivityRepository) {
        self.childId = childId
        self.activityRepository = activityRepository
    }

    /// Edit flow — pre-fills every field from the source event.
    init(existingEvent: ActivityEvent, activityRepository: ActivityRepository) {
        self.childId = existingEvent.childId
        self.activityRepository = activityRepository
        self.existingEventId = existingEvent.id
        self.activityType = existingEvent.activityType
        self.timestamp = existingEvent.timestamp
        if let dur = existingEvent.durationMinutes {
            self.durationMinutes = String(dur)
        }
        self.activityDescription = existingEvent.description
    }

    // MARK: - Actions

    /// Saves the activity event — inserts when creating, updates when editing.
    func save() async {
        isLoading = true
        errorMessage = nil

        let event = ActivityEvent(
            id: existingEventId ?? UUID().uuidString,
            childId: childId,
            activityType: activityType,
            timestamp: timestamp,
            durationMinutes: durationValue,
            description: activityDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            if isEditing {
                try await activityRepository.update(event: event)
            } else {
                try await activityRepository.insert(event: event)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save activity event. Please try again."
        }

        isLoading = false
    }

    /// Soft-deletes the event currently being edited.
    func delete() async {
        guard let id = existingEventId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await activityRepository.softDelete(eventId: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete activity event. Please try again."
        }

        isLoading = false
    }
}
