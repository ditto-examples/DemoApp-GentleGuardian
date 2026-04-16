import Foundation
import Observation

// MARK: - Repository Protocols

/// Protocol defining the write interface for feeding events needed by LogFeedingViewModel.
@MainActor
protocol LogFeedingDataSource: AnyObject {
    func insert(event: FeedingEvent) async throws
}

/// Protocol defining the write interface for custom items needed by LogFeedingViewModel.
@MainActor
protocol LogFeedingCustomItemDataSource: AnyObject {
    func insert(item: CustomItem) async throws
}

extension FeedingRepository: LogFeedingDataSource {}
extension CustomItemRepository: LogFeedingCustomItemDataSource {}

/// ViewModel managing the feeding event logging form for all three subtypes:
/// bottle, breastfeeding, and solid food.
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

    /// Whether the "Add New Formula" alert is showing.
    var showAddFormulaAlert: Bool = false

    /// New formula name being entered.
    var newFormulaName: String = ""

    // MARK: - Breast State

    /// Duration of breastfeeding in minutes.
    var breastDuration: String = ""

    /// Which breast was used.
    var breastSide: BreastSide = .left

    // MARK: - Solid State

    /// Name/type of solid food.
    var solidType: String = ""

    /// Quantity of solid food.
    var solidQuantity: String = ""

    /// Unit for solid food quantity.
    var solidUnit: QuantityUnit = .tbsp

    /// Whether the "Add New Food" alert is showing.
    var showAddFoodAlert: Bool = false

    /// New food name being entered.
    var newFoodName: String = ""

    // MARK: - UI State

    /// Whether a save is in progress.
    var isLoading: Bool = false

    /// Error message, if any.
    var errorMessage: String?

    /// Whether the event was saved successfully.
    var didSave: Bool = false

    // MARK: - Dependencies

    private let childId: String
    private let feedingRepository: any LogFeedingDataSource
    private let customItemRepository: any LogFeedingCustomItemDataSource

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

    init(childId: String, feedingRepository: any LogFeedingDataSource, customItemRepository: any LogFeedingCustomItemDataSource, initialType: FeedingType = .bottle) {
        self.childId = childId
        self.feedingRepository = feedingRepository
        self.customItemRepository = customItemRepository
        self.feedingType = initialType
    }

    // MARK: - Actions

    /// Saves the feeding event.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = FeedingEvent(
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
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await feedingRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save feeding event. Please try again."
        }

        isLoading = false
    }

    /// Adds a new custom formula item.
    func addNewFormula() async {
        let name = newFormulaName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let item = CustomItem(
            childId: childId,
            category: .formula,
            name: name
        )

        do {
            try await customItemRepository.insert(item: item)
            formulaType = name
            newFormulaName = ""
        } catch {
            errorMessage = "Failed to add formula type."
        }
    }

    /// Adds a new custom solid food item.
    func addNewFood() async {
        let name = newFoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let item = CustomItem(
            childId: childId,
            category: .solidFood,
            name: name
        )

        do {
            try await customItemRepository.insert(item: item)
            solidType = name
            newFoodName = ""
        } catch {
            errorMessage = "Failed to add food type."
        }
    }
}
