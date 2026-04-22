import Foundation
import os.log

final class VaccinationScheduleService: Sendable {
    private let schedules: [String: CountrySchedule]
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "VaccinationScheduleService")

    init() {
        guard let url = Bundle.main.url(forResource: "vaccination-schedules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: CountrySchedule].self, from: data)
        else {
            logger.error("Failed to load vaccination-schedules.json")
            schedules = [:]
            return
        }
        schedules = decoded
    }

    func schedule(for countryCode: String) -> CountrySchedule? {
        schedules[countryCode]
    }

    func ageGroups(for schedule: CountrySchedule) -> [AgeGroup] {
        var groups: [AgeGroup] = []
        var seen: Set<String> = []
        for dose in schedule.doses {
            if !seen.contains(dose.ageGroupLabel) {
                seen.insert(dose.ageGroupLabel)
                let groupDoses = schedule.doses.filter { $0.ageGroupLabel == dose.ageGroupLabel }
                groups.append(AgeGroup(label: dose.ageGroupLabel, doses: groupDoses))
            }
        }
        return groups
    }

    func status(for dose: ScheduledDose, records: [VaccinationRecord], childAgeMonths: Double) -> DoseStatus {
        let hasRecord = records.contains {
            $0.vaccineType == dose.vaccineType && $0.doseNumber == dose.doseNumber && !$0.isArchived
        }
        if hasRecord { return .completed }
        if childAgeMonths > dose.recommendedAgeMaxMonths { return .overdue }
        if childAgeMonths >= dose.recommendedAgeMinMonths { return .pending }
        return .upcoming
    }

    func groupStatus(for group: AgeGroup, records: [VaccinationRecord], childAgeMonths: Double) -> DoseStatus {
        let statuses = group.doses.map { status(for: $0, records: records, childAgeMonths: childAgeMonths) }
        if statuses.contains(.overdue) { return .overdue }
        if statuses.contains(.pending) { return .pending }
        if statuses.contains(.upcoming) { return .upcoming }
        return .completed
    }

    func progress(for schedule: CountrySchedule, records: [VaccinationRecord], childAgeMonths: Double = 0) -> VaccinationProgress {
        var completed = 0, overdue = 0, pending = 0, upcoming = 0
        for dose in schedule.doses {
            switch status(for: dose, records: records, childAgeMonths: childAgeMonths) {
            case .completed: completed += 1
            case .overdue: overdue += 1
            case .pending: pending += 1
            case .upcoming: upcoming += 1
            }
        }
        return VaccinationProgress(completed: completed, total: schedule.doses.count, overdueCount: overdue, pendingCount: pending, upcomingCount: upcoming)
    }

    func record(for dose: ScheduledDose, in records: [VaccinationRecord]) -> VaccinationRecord? {
        records.first { $0.vaccineType == dose.vaccineType && $0.doseNumber == dose.doseNumber && !$0.isArchived }
    }

    static func ageString(from birthday: Date, to date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthday, to: date)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        if years > 0 {
            if months > 0 { return "\(years)y \(months)m" }
            return "\(years)y"
        }
        if months > 0 {
            if days > 0 { return "\(months)m \(days)d" }
            return "\(months)m"
        }
        return "\(max(days, 0))d"
    }

    static func ageInMonths(from birthday: Date, to date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthday, to: date)
        let months = Double(components.month ?? 0)
        let days = Double(components.day ?? 0)
        return months + (days / 30.44)
    }
}
