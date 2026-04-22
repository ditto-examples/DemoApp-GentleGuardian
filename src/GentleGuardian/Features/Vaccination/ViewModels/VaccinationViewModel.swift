import Foundation
import Observation

/// ViewModel for the main vaccination tab view.
/// Aggregates schedule data, records, and computes age group statuses.
@Observable
@MainActor
final class VaccinationViewModel {

    // MARK: - Dependencies

    private let vaccinationRepository: VaccinationRepository
    private let scheduleService = VaccinationScheduleService()

    // MARK: - State

    /// The active child.
    var child: Child?

    /// The resolved country schedule.
    var schedule: CountrySchedule?

    /// Age groups derived from the schedule.
    var ageGroups: [AgeGroup] = []

    /// Vaccination records from the repository (filtered, non-archived).
    var records: [VaccinationRecord] { vaccinationRepository.records }

    /// "Other" (ad-hoc) vaccination records.
    var otherRecords: [VaccinationRecord] {
        records.filter { $0.vaccineType == VaccineType.other.rawValue }
    }

    // MARK: - Initialization

    init(vaccinationRepository: VaccinationRepository) {
        self.vaccinationRepository = vaccinationRepository
    }

    // MARK: - Setup

    /// Loads the schedule and starts observing records for the active child.
    func loadChild(_ child: Child) {
        self.child = child

        let countryCode = child.vaccinationCountry ?? "US"
        schedule = scheduleService.schedule(for: countryCode)

        if let schedule {
            ageGroups = scheduleService.ageGroups(for: schedule)
        }

        vaccinationRepository.observeRecords(childId: child.id)
    }

    // MARK: - Computed Properties

    /// The child's current age in months.
    var childAgeMonths: Double {
        guard let child else { return 0 }
        return VaccinationScheduleService.ageInMonths(from: child.birthday, to: Date())
    }

    /// Progress for the overall schedule.
    var progress: VaccinationProgress {
        guard let schedule else {
            return VaccinationProgress(completed: 0, total: 0, overdueCount: 0, pendingCount: 0, upcomingCount: 0)
        }
        return scheduleService.progress(for: schedule, records: records, childAgeMonths: childAgeMonths)
    }

    /// Status for a specific age group.
    func groupStatus(for group: AgeGroup) -> DoseStatus {
        scheduleService.groupStatus(for: group, records: records, childAgeMonths: childAgeMonths)
    }

    /// Status for a specific dose.
    func doseStatus(for dose: ScheduledDose) -> DoseStatus {
        scheduleService.status(for: dose, records: records, childAgeMonths: childAgeMonths)
    }

    /// The matching record for a dose, if completed.
    func record(for dose: ScheduledDose) -> VaccinationRecord? {
        scheduleService.record(for: dose, in: records)
    }

    /// Number of completed doses in an age group.
    func completedCount(for group: AgeGroup) -> Int {
        group.doses.filter { doseStatus(for: $0) == .completed }.count
    }

    /// Number of remaining (non-completed) doses in an age group.
    func remainingDoses(for group: AgeGroup) -> [ScheduledDose] {
        group.doses.filter { doseStatus(for: $0) != .completed }
    }

    /// The schedule source display name.
    var scheduleSourceName: String {
        schedule?.source ?? ""
    }

    /// Date when child reached a given age group label (for display).
    func childDateForAgeGroup(_ group: AgeGroup) -> String? {
        guard let child, let firstDose = group.doses.first else { return nil }
        let calendar = Calendar.current
        let months = Int(firstDose.recommendedAgeMinMonths)
        guard let date = calendar.date(byAdding: .month, value: months, to: child.birthday) else { return nil }

        if months == 0 {
            return DateService.displayDate(from: child.birthday)
        }
        return DateService.displayDate(from: date)
    }
}
