import Foundation
import Observation

/// ViewModel managing the health event logging form for all three subtypes:
/// medicine, temperature, and growth measurement.
@Observable
@MainActor
final class LogHealthViewModel {

    // MARK: - Common State

    /// The type of health event being logged.
    var healthType: HealthEventType = .medicine

    /// When the health event occurred (defaults to now).
    var timestamp: Date = Date()

    /// Optional notes.
    var notes: String = ""

    // MARK: - Medicine State

    /// Name of medicine.
    var medicineName: String = ""

    /// Dosage quantity.
    var medicineQuantity: String = ""

    /// Dosage unit.
    var medicineUnit: MedicineUnit = .ml

    /// Whether the "Add New Medicine" alert is showing.
    var showAddMedicineAlert: Bool = false

    /// New medicine name being entered.
    var newMedicineName: String = ""

    // MARK: - Temperature State

    /// Temperature reading.
    var temperatureValue: String = ""

    /// Temperature unit.
    var temperatureUnit: TemperatureUnit = .fahrenheit

    // MARK: - Growth State

    /// Height measurement.
    var heightValue: String = ""

    /// Height unit.
    var heightUnit: HeightUnit = .inches

    /// Weight measurement.
    var weightValue: String = ""

    /// Weight unit.
    var weightUnit: WeightUnit = .lb

    // MARK: - UI State

    /// Whether a save is in progress.
    var isLoading: Bool = false

    /// Error message, if any.
    var errorMessage: String?

    /// Whether the event was saved successfully.
    var didSave: Bool = false

    // MARK: - Validation

    /// Whether the form is valid for the current health type.
    var isFormValid: Bool {
        switch healthType {
        case .medicine:
            return !medicineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .temperature:
            return temperatureDoubleValue != nil
        case .growth:
            return heightDoubleValue != nil || weightDoubleValue != nil
        }
    }

    /// Parsed medicine quantity, or nil if invalid.
    var medicineQuantityValue: Double? {
        medicineQuantity.isEmpty ? nil : Double(medicineQuantity)
    }

    /// Parsed temperature value, or nil if invalid.
    var temperatureDoubleValue: Double? {
        Double(temperatureValue)
    }

    /// Parsed height value, or nil if invalid.
    var heightDoubleValue: Double? {
        heightValue.isEmpty ? nil : Double(heightValue)
    }

    /// Parsed weight value, or nil if invalid.
    var weightDoubleValue: Double? {
        weightValue.isEmpty ? nil : Double(weightValue)
    }

    // MARK: - Dependencies

    private let childId: String
    private let healthRepository: HealthRepository
    private let customItemRepository: CustomItemRepository

    // MARK: - Initialization

    init(childId: String, healthRepository: HealthRepository, customItemRepository: CustomItemRepository, initialType: HealthEventType = .medicine) {
        self.childId = childId
        self.healthRepository = healthRepository
        self.customItemRepository = customItemRepository
        self.healthType = initialType
    }

    // MARK: - Actions

    /// Saves the health event.
    func save() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let event = HealthEvent(
            childId: childId,
            type: healthType,
            timestamp: timestamp,
            medicineName: healthType == .medicine ? medicineName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            medicineQuantity: healthType == .medicine ? medicineQuantityValue : nil,
            medicineQuantityUnit: healthType == .medicine && medicineQuantityValue != nil ? medicineUnit : nil,
            temperatureValue: healthType == .temperature ? temperatureDoubleValue : nil,
            temperatureUnit: healthType == .temperature ? temperatureUnit : nil,
            heightValue: healthType == .growth ? heightDoubleValue : nil,
            heightUnit: healthType == .growth && heightDoubleValue != nil ? heightUnit : nil,
            weightValue: healthType == .growth ? weightDoubleValue : nil,
            weightUnit: healthType == .growth && weightDoubleValue != nil ? weightUnit : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await healthRepository.insert(event: event)
            didSave = true
        } catch {
            errorMessage = "Failed to save health event. Please try again."
        }

        isLoading = false
    }

    /// Adds a new custom medicine item.
    func addNewMedicine() async {
        let name = newMedicineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let item = CustomItem(
            childId: childId,
            category: .medicine,
            name: name
        )

        do {
            try await customItemRepository.insert(item: item)
            medicineName = name
            newMedicineName = ""
        } catch {
            errorMessage = "Failed to add medicine type."
        }
    }
}
