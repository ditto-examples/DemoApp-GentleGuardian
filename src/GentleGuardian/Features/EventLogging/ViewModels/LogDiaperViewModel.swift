import Foundation
import Observation

// MARK: - Repository Protocol

/// Protocol defining the write interface needed by LogDiaperViewModel.
@MainActor
protocol LogDiaperDataSource: AnyObject {
    func insert(event: DiaperEvent) async throws
}

extension DiaperRepository: LogDiaperDataSource {}

/// ViewModel managing the diaper event logging form with conditional fields
/// for poop vs pee.
@Observable
@MainActor
final class LogDiaperViewModel {

    // MARK: - Form State

    /// Type of diaper change.
    var diaperType: DiaperType = .pee

    /// Qualitative amount.
    var quantity: DiaperQuantity = .medium

    /// Color of stool (poop only).
    var color: DiaperColor = .brown

    /// Consistency of stool (poop only).
    var consistency: DiaperConsistency = .solid

    /// When the diaper change occurred (defaults to now).
    var timestamp: Date = Date()

    /// Optional notes.
    var notes: String = ""

    // MARK: - UI State

    /// Whether a save is in progress.
    var isLoading: Bool = false

    /// Error message, if any.
    var errorMessage: String?

    /// Whether the event was saved successfully.
    var didSave: Bool = false

    // MARK: - Validation

    /// The form is always valid for diaper events since all fields have defaults.
    var isFormValid: Bool {
        true
    }

    /// Whether poop-specific fields should be shown.
    var showPoopFields: Bool {
        diaperType == .poop
    }

    // MARK: - Dependencies

    private let childId: String
    private let diaperRepository: any LogDiaperDataSource

    // MARK: - Initialization

    init(childId: String, diaperRepository: any LogDiaperDataSource) {
        self.childId = childId
        self.diaperRepository = diaperRepository
    }

    // MARK: - Actions

    /// Saves the diaper event.
    func save() async {
        isLoading = true
        errorMessage = nil

        let event = DiaperEvent(
            childId: childId,
            type: diaperType,
            timestamp: timestamp,
            quantity: quantity,
            color: diaperType == .poop ? color : nil,
            consistency: diaperType == .poop ? consistency : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await diaperRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save diaper event. Please try again."
        }

        isLoading = false
    }
}
