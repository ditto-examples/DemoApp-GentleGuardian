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

    // MARK: - Actions

    /// Saves the activity event.
    func save() async {
        isLoading = true
        errorMessage = nil

        let event = ActivityEvent(
            childId: childId,
            activityType: activityType,
            timestamp: timestamp,
            durationMinutes: durationValue,
            description: activityDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await activityRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save activity event. Please try again."
        }

        isLoading = false
    }
}
