import Foundation
import Observation

// MARK: - Repository Protocols

/// Protocol defining the read/write interface for feeding events needed by
/// `LogFeedingViewModel`. Used in both create and edit flows; mocked in tests.
@MainActor
protocol LogFeedingDataSource: AnyObject {
    func insert(event: FeedingEvent) async throws
    func update(event: FeedingEvent) async throws
    func softDelete(eventId: String) async throws
}

extension FeedingRepository: LogFeedingDataSource {}

/// ViewModel managing the feeding event logging form for all three subtypes:
/// bottle, breastfeeding, and solid food.
///
/// Supports both **create** and **edit** flows. In edit mode the view model
/// is constructed via `init(existingEvent:repository:)` which pre-fills every
/// field from the source event. `save()` then routes to either insert or
/// update depending on whether `existingEventId` is set, and `delete()`
/// soft-deletes the underlying event.
@Observable
@MainActor
final class LogFeedingViewModel {

    // MARK: - Common State

    /// The type of feeding being logged.
    var feedingType: FeedingType = .bottle

    /// When the feeding occurred (defaults to now).
    var timestamp: Date = Date()

    /// Optional notes about this feeding.
    var notes: String = ""

    // MARK: - Bottle State

    /// Quantity of liquid consumed.
    var bottleQuantity: String = ""

    /// Unit for bottle quantity.
    var bottleUnit: VolumeUnit = .oz

    /// Selected formula type name.
    var formulaType: String = ""

    /// Optional attachment token for the selected formula's photo (display only — not persisted on the event).
    var formulaAttachmentToken: String?

    // MARK: - Breast State

    /// Duration of breastfeeding in minutes.
    var breastDuration: String = ""

    /// Which breast was used.
    var breastSide: BreastSide = .left

    // MARK: - Solid State

    /// Name/type of solid food.
    var solidType: String = ""

    /// Optional attachment token for the selected food's photo (display only — not persisted on the event).
    var solidAttachmentToken: String?

    /// Quantity of solid food.
    var solidQuantity: String = ""

    /// Unit for solid food quantity.
    var solidUnit: QuantityUnit = .tbsp

    /// Caregiver-recorded reaction. `nil` means "not rated".
    var solidReaction: SolidReaction?

    // MARK: - UI State

    /// Whether a save is in progress.
    var isLoading: Bool = false

    /// Error message, if any.
    var errorMessage: String?

    /// Whether the event was saved successfully.
    var didSave: Bool = false

    /// Whether a delete just succeeded — Edit sheet listens to this and dismisses.
    var didDelete: Bool = false

    // MARK: - Edit Mode

    /// Set when this view model edits an existing event. `nil` for create flow.
    private(set) var existingEventId: String?

    /// `true` when this view model is editing an existing event.
    var isEditing: Bool { existingEventId != nil }

    // MARK: - Dependencies

    private let childId: String
    private let feedingRepository: any LogFeedingDataSource

    // MARK: - Validation

    /// Whether the form is valid for the current feeding type.
    var isFormValid: Bool {
        switch feedingType {
        case .bottle:
            return bottleQuantityValue != nil
        case .breast:
            return breastDurationValue != nil
        case .solid:
            return !solidType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Parsed bottle quantity, or nil if invalid.
    var bottleQuantityValue: Double? {
        Double(bottleQuantity)
    }

    /// Parsed breast duration, or nil if invalid.
    var breastDurationValue: Int? {
        Int(breastDuration)
    }

    /// Parsed solid quantity, or nil if invalid.
    var solidQuantityValue: Double? {
        solidQuantity.isEmpty ? nil : Double(solidQuantity)
    }

    // MARK: - Initialization

    /// Create flow.
    init(childId: String, feedingRepository: any LogFeedingDataSource, initialType: FeedingType = .bottle) {
        self.childId = childId
        self.feedingRepository = feedingRepository
        self.feedingType = initialType
    }

    /// Edit flow — pre-fills every field from the source event.
    init(existingEvent: FeedingEvent, feedingRepository: any LogFeedingDataSource) {
        self.childId = existingEvent.childId
        self.feedingRepository = feedingRepository
        self.existingEventId = existingEvent.id
        self.feedingType = existingEvent.type
        self.timestamp = existingEvent.timestamp
        self.notes = existingEvent.notes

        if let qty = existingEvent.bottleQuantity {
            self.bottleQuantity = formattedNumber(qty)
        }
        if let unit = existingEvent.bottleQuantityUnit {
            self.bottleUnit = unit
        }
        self.formulaType = existingEvent.formulaType ?? ""

        if let dur = existingEvent.breastDurationMinutes {
            self.breastDuration = String(dur)
        }
        if let side = existingEvent.breastSide {
            self.breastSide = side
        }

        self.solidType = existingEvent.solidType ?? ""
        if let qty = existingEvent.solidQuantity {
            self.solidQuantity = formattedNumber(qty)
        }
        if let unit = existingEvent.solidQuantityUnit {
            self.solidUnit = unit
        }
        self.solidReaction = existingEvent.solidReaction
    }

    // MARK: - Actions

    /// Saves the feeding event — inserts when creating, updates when editing.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = FeedingEvent(
            id: existingEventId ?? UUID().uuidString,
            childId: childId,
            type: feedingType,
            timestamp: timestamp,
            bottleQuantity: feedingType == .bottle ? bottleQuantityValue : nil,
            bottleQuantityUnit: feedingType == .bottle ? bottleUnit : nil,
            formulaType: feedingType == .bottle && !formulaType.isEmpty ? formulaType : nil,
            breastDurationMinutes: feedingType == .breast ? breastDurationValue : nil,
            breastSide: feedingType == .breast ? breastSide : nil,
            solidType: feedingType == .solid ? solidType.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            solidQuantity: feedingType == .solid ? solidQuantityValue : nil,
            solidQuantityUnit: feedingType == .solid && solidQuantityValue != nil ? solidUnit : nil,
            solidReaction: feedingType == .solid ? solidReaction : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            if isEditing {
                try await feedingRepository.update(event: event)
            } else {
                try await feedingRepository.insert(event: event)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save feeding event. Please try again."
        }

        isLoading = false
    }

    /// Soft-deletes the event currently being edited. No-op for create flow.
    func delete() async {
        guard let id = existingEventId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await feedingRepository.softDelete(eventId: id)
            didDelete = true
        } catch {
            errorMessage = "Failed to delete feeding event. Please try again."
        }

        isLoading = false
    }
}

// MARK: - Helpers

/// Strips trailing `.0` so `4.0` displays as `4` in the form, while
/// preserving real decimals like `4.5`.
private func formattedNumber(_ value: Double) -> String {
    if value == value.rounded() {
        return String(Int(value))
    }
    return String(value)
}
