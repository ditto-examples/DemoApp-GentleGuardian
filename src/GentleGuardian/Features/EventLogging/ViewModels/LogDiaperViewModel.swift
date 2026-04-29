import Foundation
import Observation

// MARK: - Repository Protocol

/// Protocol defining the read/write interface needed by LogDiaperViewModel.
/// Used in both create and edit flows.
@MainActor
protocol LogDiaperDataSource: AnyObject {
    func insert(event: DiaperEvent) async throws
    func update(event: DiaperEvent) async throws
    func softDelete(eventId: String) async throws
}

extension DiaperRepository: LogDiaperDataSource {}

/// ViewModel managing the diaper event logging form with conditional fields
/// for poop vs pee. Supports both create and edit flows.
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

    /// Whether a delete just succeeded.
    var didDelete: Bool = false

    // MARK: - Edit Mode

    private(set) var existingEventId: String?

    var isEditing: Bool { existingEventId != nil }

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

    /// Create flow.
    init(childId: String, diaperRepository: any LogDiaperDataSource) {
        self.childId = childId
        self.diaperRepository = diaperRepository
    }

    /// Edit flow — pre-fills every field from the source event.
    init(existingEvent: DiaperEvent, diaperRepository: any LogDiaperDataSource) {
        self.childId = existingEvent.childId
        self.diaperRepository = diaperRepository
        self.existingEventId = existingEvent.id
        self.diaperType = existingEvent.type
        self.timestamp = existingEvent.timestamp
        self.quantity = existingEvent.quantity
        if let color = existingEvent.color { self.color = color }
        if let consistency = existingEvent.consistency { self.consistency = consistency }
        self.notes = existingEvent.notes
    }

    // MARK: - Actions

    /// Saves the diaper event — inserts when creating, updates when editing.
    func save() async {
        isLoading = true
        errorMessage = nil

        let event = DiaperEvent(
            id: existingEventId ?? UUID().uuidString,
            childId: childId,
            type: diaperType,
            timestamp: timestamp,
            quantity: quantity,
            color: diaperType == .poop ? color : nil,
            consistency: diaperType == .poop ? consistency : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            if isEditing {
                try await diaperRepository.update(event: event)
            } else {
                try await diaperRepository.insert(event: event)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save diaper event. Please try again."
        }

        isLoading = false
    }

    /// Soft-deletes the event currently being edited.
    func delete() async {
        guard let id = existingEventId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await diaperRepository.softDelete(eventId: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete diaper event. Please try again."
        }

        isLoading = false
    }
}
