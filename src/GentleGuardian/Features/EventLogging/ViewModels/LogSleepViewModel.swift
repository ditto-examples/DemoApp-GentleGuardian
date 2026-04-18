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

    // MARK: - Actions

    /// Saves the sleep event.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = SleepEvent(
            childId: childId,
            startTime: startTime,
            endTime: endTime,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await sleepRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save sleep event. Please try again."
        }

        isLoading = false
    }
}
