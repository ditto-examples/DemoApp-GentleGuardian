import Foundation
import Observation

// MARK: - Repository Protocol

/// Protocol defining the child-insert interface needed by RegisterChildViewModel.
@MainActor
protocol RegisterChildDataSource: AnyObject {
    func insert(child: Child) async throws
}

extension ChildRepository: RegisterChildDataSource {}

/// ViewModel managing the registration form for adding a new child.
///
/// Handles form validation, sync code generation, and child creation
/// via the ChildRepository. Updates ActiveChildState upon success.
@Observable
@MainActor
final class RegisterChildViewModel {

    // MARK: - Form State

    /// The caregiver's full name (used for Ditto peer metadata).
    var userFullName: String = ""

    /// The child's first name.
    var firstName: String = ""

    /// The child's date of birth.
    var birthday: Date = Date()

    /// Biological sex selection.
    var sex: Sex = .other

    /// Whether the prematurity option is toggled on.
    var isPremature: Bool = false

    /// Number of weeks premature (gestational age at birth).
    var prematurityWeeks: Int = 37

    /// Whether vaccination tracking is enabled.
    var isVaccinationTrackingEnabled: Bool = false

    /// Selected vaccination region.
    var vaccinationRegion: VaccinationRegion = .usa

    /// Selected country code for vaccination schedule.
    var vaccinationCountryCode: String = "US"

    // MARK: - UI State

    /// Whether a save operation is in progress.
    var isLoading: Bool = false

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether registration completed successfully.
    var didComplete: Bool = false

    // MARK: - Validation

    /// Whether the form is valid for submission.
    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && birthday < Date()
            && (userSettings == nil || !userFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    /// Validation message for the name field.
    var nameValidationMessage: String? {
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !firstName.isEmpty {
            return "Name is required"
        }
        return nil
    }

    /// Validation message for the birthday field.
    var birthdayValidationMessage: String? {
        if birthday > Date() {
            return "Birthday must be in the past"
        }
        return nil
    }

    // MARK: - Dependencies

    private let childRepository: any RegisterChildDataSource
    private let activeChildState: ActiveChildState
    private let dittoManager: (any DittoManaging)?
    private let userSettings: UserSettings?

    // MARK: - Initialization

    init(
        childRepository: any RegisterChildDataSource,
        activeChildState: ActiveChildState,
        dittoManager: (any DittoManaging)? = nil,
        userSettings: UserSettings? = nil
    ) {
        self.childRepository = childRepository
        self.activeChildState = activeChildState
        self.dittoManager = dittoManager
        self.userSettings = userSettings
        self.userFullName = userSettings?.displayName ?? ""
    }

    // MARK: - Computed Properties

    /// Computes the prematurity status based on the selected weeks.
    var computedPrematurityStatus: PrematurityStatus? {
        guard isPremature else { return nil }
        for status in PrematurityStatus.allCases {
            if status.weeksRange.contains(prematurityWeeks) {
                return status
            }
        }
        return nil
    }

    // MARK: - Actions

    /// Submits the registration form, creating a new child record.
    func submit() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let syncCode = SyncCodeGenerator.generate()
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        let child = Child(
            firstName: trimmedName,
            birthday: birthday,
            sex: sex,
            prematurityWeeks: isPremature ? prematurityWeeks : nil,
            prematurityStatus: computedPrematurityStatus,
            syncCode: syncCode,
            vaccinationRegion: isVaccinationTrackingEnabled ? vaccinationRegion.rawValue : nil,
            vaccinationCountry: isVaccinationTrackingEnabled ? (vaccinationRegion == .usa ? "US" : vaccinationCountryCode) : nil,
            isVaccinationTrackingEnabled: isVaccinationTrackingEnabled
        )

        do {
            try await childRepository.insert(child: child)

            // Subscribe to sync data for this child
            if let dittoManager {
                await dittoManager.subscribeToChildData(childId: child.id)
            }

            // Save the caregiver name and set peer metadata
            let trimmedUserName = userFullName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedUserName.isEmpty, let userSettings {
                userSettings.displayName = trimmedUserName
                try? await dittoManager?.setPeerMetadata(displayName: trimmedUserName)
            }

            // Update the active child state
            activeChildState.updateChildren(activeChildState.children + [child])
            activeChildState.selectChild(child.id)

            didComplete = true
        } catch {
            errorMessage = "Failed to register child. Please try again."
        }

        isLoading = false
    }
}
