import Foundation
import Observation
#if os(iOS)
import UIKit
#endif

/// ViewModel managing the child profile view with editing, sync code display,
/// and tracking day settings.
@Observable
@MainActor
final class ChildProfileViewModel {

    // MARK: - Child Data

    /// The child being displayed/edited.
    var child: Child?

    // MARK: - Edit State

    /// Editable first name.
    var editFirstName: String = ""

    /// Editable birthday.
    var editBirthday: Date = Date()

    /// Editable sex.
    var editSex: Sex = .other

    /// Editable prematurity toggle.
    var editIsPremature: Bool = false

    /// Editable prematurity weeks.
    var editPrematurityWeeks: Int = 37

    /// Editable tracking day start hour.
    var editDayStartHour: Int = AppConstants.defaultDayStartHour

    /// Editable tracking day end hour.
    var editDayEndHour: Int = AppConstants.defaultDayEndHour

    /// Editable vaccination tracking toggle.
    var editIsVaccinationTrackingEnabled: Bool = false

    /// Editable vaccination region.
    var editVaccinationRegion: VaccinationRegion = .usa

    /// Editable vaccination country code.
    var editVaccinationCountryCode: String = "US"

    // MARK: - UI State

    /// Whether a save operation is in progress.
    var isLoading: Bool = false

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether profile was saved successfully.
    var didSave: Bool = false

    /// Whether the sync code was copied to clipboard.
    var didCopySyncCode: Bool = false

    // MARK: - Computed Properties

    /// Whether any editable fields have changed from the original child data.
    var hasChanges: Bool {
        guard let child else { return false }
        return editFirstName != child.firstName
            || editBirthday != child.birthday
            || editSex != child.sex
            || editIsPremature != (child.prematurityWeeks != nil)
            || (editIsPremature && editPrematurityWeeks != (child.prematurityWeeks ?? 37))
            || editDayStartHour != child.dayStartHour
            || editDayEndHour != child.dayEndHour
            || editIsVaccinationTrackingEnabled != child.isVaccinationTrackingEnabled
            || editVaccinationRegion.rawValue != (child.vaccinationRegion ?? VaccinationRegion.usa.rawValue)
            || editVaccinationCountryCode != (child.vaccinationCountry ?? "US")
    }

    /// Whether the form is valid for saving.
    var isFormValid: Bool {
        !editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The sync code split into individual characters for display.
    var syncCodeCharacters: [Character] {
        guard let child else { return [] }
        return Array(child.syncCode)
    }

    /// Computes the prematurity status based on the selected weeks.
    var computedPrematurityStatus: PrematurityStatus? {
        guard editIsPremature else { return nil }
        for status in PrematurityStatus.allCases {
            if status.weeksRange.contains(editPrematurityWeeks) {
                return status
            }
        }
        return nil
    }

    /// The child's age as a human-readable string.
    var ageDescription: String {
        guard let child else { return "" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: child.birthday, to: Date())

        if let years = components.year, years > 0 {
            if let months = components.month, months > 0 {
                return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s") old"
            }
            return "\(years) year\(years == 1 ? "" : "s") old"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") old"
        }
        return "Newborn"
    }

    // MARK: - Dependencies

    private let childRepository: ChildRepository

    // MARK: - Initialization

    init(childRepository: ChildRepository) {
        self.childRepository = childRepository
    }

    // MARK: - Actions

    /// Loads child data and populates edit fields.
    func loadChild(_ child: Child) {
        self.child = child
        editFirstName = child.firstName
        editBirthday = child.birthday
        editSex = child.sex
        editIsPremature = child.prematurityWeeks != nil
        editPrematurityWeeks = child.prematurityWeeks ?? 37
        editDayStartHour = child.dayStartHour
        editDayEndHour = child.dayEndHour
        editIsVaccinationTrackingEnabled = child.isVaccinationTrackingEnabled
        editVaccinationRegion = VaccinationRegion(rawValue: child.vaccinationRegion ?? "") ?? .usa
        editVaccinationCountryCode = child.vaccinationCountry ?? "US"
    }

    /// Saves the edited profile back to the repository.
    func saveProfile() async {
        guard isFormValid, var updatedChild = child else { return }

        isLoading = true
        errorMessage = nil
        didSave = false

        updatedChild.firstName = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedChild.birthday = editBirthday
        updatedChild.sex = editSex
        updatedChild.prematurityWeeks = editIsPremature ? editPrematurityWeeks : nil
        updatedChild.prematurityStatus = computedPrematurityStatus
        updatedChild.dayStartHour = editDayStartHour
        updatedChild.dayEndHour = editDayEndHour
        updatedChild.isVaccinationTrackingEnabled = editIsVaccinationTrackingEnabled
        updatedChild.vaccinationRegion = editIsVaccinationTrackingEnabled ? editVaccinationRegion.rawValue : nil
        updatedChild.vaccinationCountry = editIsVaccinationTrackingEnabled ? (editVaccinationRegion == .usa ? "US" : editVaccinationCountryCode) : nil

        do {
            try await childRepository.update(child: updatedChild)

            child = updatedChild
            didSave = true
        } catch {
            errorMessage = "Failed to save profile. Please try again."
        }

        isLoading = false
    }

    /// Copies the sync code to the system clipboard.
    func copySyncCodeToClipboard() {
        guard let child else { return }
        #if os(iOS)
        UIPasteboard.general.string = child.syncCode
        #endif
        didCopySyncCode = true

        // Reset the "copied" flag after a brief delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            didCopySyncCode = false
        }
    }
}
