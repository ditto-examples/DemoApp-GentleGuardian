import Foundation
import Observation

/// ViewModel managing the sleep event logging form.
@Observable
@MainActor
final class LogSleepViewModel {

    // MARK: - Form State

    /// When the child fell asleep (defaults to 1 hour ago).
    var startTime: Date = Date().addingTimeInterval(-3600)

    /// When the child woke up (defaults to now).
    var endTime: Date = Date()

    /// Optional notes about this sleep session.
    var notes: String = ""

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

    /// The form is valid when the end time is after the start time.
    var isFormValid: Bool {
        endTime > startTime
    }

    /// Validation message when times are invalid.
    var timeValidationMessage: String? {
        guard endTime <= startTime else { return nil }
        return "Wake up time must be after sleep time"
    }

    /// Computed duration in minutes from the selected times.
    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    /// Human-readable duration label.
    var durationLabel: String {
        let mins = durationMinutes
        if mins >= 60 {
            let hours = mins / 60
            let minutes = mins % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(mins)m"
    }

    // MARK: - Dependencies

    private let childId: String
    private let sleepRepository: SleepRepository

    // MARK: - Initialization

    init(childId: String, sleepRepository: SleepRepository) {
        self.childId = childId
        self.sleepRepository = sleepRepository
    }

    /// Edit flow — pre-fills every field from the source event.
    init(existingEvent: SleepEvent, sleepRepository: SleepRepository) {
        self.childId = existingEvent.childId
        self.sleepRepository = sleepRepository
        self.existingEventId = existingEvent.id
        self.startTime = existingEvent.startTime
        self.endTime = existingEvent.endTime
        self.notes = existingEvent.notes
    }

    // MARK: - Actions

    /// Saves the sleep event — inserts when creating, updates when editing.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = SleepEvent(
            id: existingEventId ?? UUID().uuidString,
            childId: childId,
            startTime: startTime,
            endTime: endTime,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            if isEditing {
                try await sleepRepository.update(event: event)
            } else {
                try await sleepRepository.insert(event: event)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save sleep event. Please try again."
        }

        isLoading = false
    }

    /// Soft-deletes the event currently being edited.
    func delete() async {
        guard let id = existingEventId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await sleepRepository.softDelete(eventId: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete sleep event. Please try again."
        }

        isLoading = false
    }
}
