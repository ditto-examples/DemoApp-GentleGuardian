import Foundation
import Observation

/// ViewModel for logging individual, batch, and "other" vaccinations.
@Observable
@MainActor
final class LogVaccinationViewModel {

    // MARK: - Dependencies

    private let vaccinationRepository: VaccinationRepository

    // MARK: - State

    /// The child being vaccinated.
    var child: Child?

    /// Date administered (constrained in the view to birthday...today).
    var dateAdministered: Date = Date()

    /// Optional notes.
    var notes: String = ""

    /// For batch logging: which doses are selected.
    var selectedDoses: Set<String> = []

    /// For "other" type: custom vaccine name.
    var customVaccineName: String = ""

    /// For "other" type: custom vaccine description.
    var customVaccineDescription: String = ""

    /// Whether a save operation is in progress.
    var isSaving: Bool = false

    /// Whether the save completed successfully.
    var didSave: Bool = false

    /// Error message to display.
    var errorMessage: String?

    // MARK: - Initialization

    init(vaccinationRepository: VaccinationRepository) {
        self.vaccinationRepository = vaccinationRepository
    }

    // MARK: - Computed

    /// The child's age at the selected date.
    var ageAtDate: String {
        guard let child else { return "" }
        return VaccinationScheduleService.ageString(from: child.birthday, to: dateAdministered)
    }

    /// Date range for the date picker.
    var dateRange: ClosedRange<Date> {
        let floor = child?.birthday ?? Date.distantPast
        return floor...Date()
    }

    /// Whether the "other" form is valid.
    var isOtherFormValid: Bool {
        !customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Saves a single dose vaccination record.
    func saveIndividual(dose: ScheduledDose) async {
        guard let child else { return }
        isSaving = true
        errorMessage = nil

        let record = VaccinationRecord(
            childId: child.id,
            vaccineType: dose.vaccineType,
            doseNumber: dose.doseNumber,
            dateAdministered: dateAdministered,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await vaccinationRepository.insert(record: record)
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination record."
        }
        isSaving = false
    }

    /// Saves multiple dose vaccination records (batch logging).
    func saveBatch(doses: [ScheduledDose]) async {
        guard let child else { return }
        isSaving = true
        errorMessage = nil

        let selected = doses.filter { selectedDoses.contains($0.id) }

        do {
            for dose in selected {
                let record = VaccinationRecord(
                    childId: child.id,
                    vaccineType: dose.vaccineType,
                    doseNumber: dose.doseNumber,
                    dateAdministered: dateAdministered,
                    notes: notes.isEmpty ? nil : notes
                )
                try await vaccinationRepository.insert(record: record)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination records."
        }
        isSaving = false
    }

    /// Saves an "other" (ad-hoc) vaccination record.
    func saveOther() async {
        guard let child, isOtherFormValid else { return }
        isSaving = true
        errorMessage = nil

        let record = VaccinationRecord(
            childId: child.id,
            vaccineType: VaccineType.other.rawValue,
            doseNumber: 0,
            dateAdministered: dateAdministered,
            notes: notes.isEmpty ? nil : notes,
            customVaccineName: customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines),
            customVaccineDescription: customVaccineDescription.isEmpty ? nil : customVaccineDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await vaccinationRepository.insert(record: record)
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination record."
        }
        isSaving = false
    }

    /// Updates an existing vaccination record.
    func updateRecord(_ record: VaccinationRecord) async {
        isSaving = true
        errorMessage = nil

        var updated = record
        updated.dateAdministered = dateAdministered
        updated.notes = notes.isEmpty ? nil : notes
        if record.vaccineType == VaccineType.other.rawValue {
            updated.customVaccineName = customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.customVaccineDescription = customVaccineDescription.isEmpty ? nil : customVaccineDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            try await vaccinationRepository.update(record: updated)
            didSave = true
        } catch {
            errorMessage = "Failed to update vaccination record."
        }
        isSaving = false
    }

    /// Soft-deletes a vaccination record.
    func deleteRecord(_ record: VaccinationRecord) async {
        isSaving = true
        errorMessage = nil

        do {
            try await vaccinationRepository.softDelete(recordId: record.id)
            didSave = true
        } catch {
            errorMessage = "Failed to delete vaccination record."
        }
        isSaving = false
    }

    /// Initializes batch selection with all remaining doses selected.
    func initBatchSelection(doses: [ScheduledDose]) {
        selectedDoses = Set(doses.map(\.id))
    }

    /// Loads an existing record for editing.
    func loadRecord(_ record: VaccinationRecord) {
        dateAdministered = record.dateAdministered
        notes = record.notes ?? ""
        customVaccineName = record.customVaccineName ?? ""
        customVaccineDescription = record.customVaccineDescription ?? ""
    }
}
