import Testing
import Foundation
@testable import GentleGuardian

struct VaccinationScheduleServiceTests {

    @Test func loadUSSchedule() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")
        #expect(schedule != nil)
        #expect(schedule!.name.contains("United States"))
        #expect(!schedule!.doses.isEmpty)
    }

    @Test func loadGermanySchedule() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "DE")
        #expect(schedule != nil)
        #expect(schedule!.name.contains("Germany"))
        #expect(!schedule!.doses.isEmpty)
    }

    @Test func invalidCountryReturnsNil() {
        let service = VaccinationScheduleService()
        #expect(service.schedule(for: "XX") == nil)
    }

    @Test func allCountriesHaveSchedules() {
        let service = VaccinationScheduleService()
        let allCodes = ["US"] + VaccinationRegion.europe.countries.map(\.code)
        for code in allCodes {
            let schedule = service.schedule(for: code)
            #expect(schedule != nil, "Missing schedule for \(code)")
            #expect(!schedule!.doses.isEmpty, "Empty doses for \(code)")
        }
    }

    @Test func ageGroupsAreGroupedByLabel() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")!
        let groups = service.ageGroups(for: schedule)
        #expect(!groups.isEmpty)
        #expect(groups[0].label == "Birth")
        for group in groups { #expect(!group.doses.isEmpty) }
    }

    @Test func completedDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(vaccineType: "hepB", doseNumber: 1, recommendedAgeMinMonths: 0, recommendedAgeMaxMonths: 0, ageGroupLabel: "Birth", displayName: "Hepatitis B", abbreviation: "HepB")
        let record = VaccinationRecord(childId: "child-1", vaccineType: "hepB", doseNumber: 1, dateAdministered: Date())
        #expect(service.status(for: dose, records: [record], childAgeMonths: 2.0) == .completed)
    }

    @Test func overdueDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(vaccineType: "dtap", doseNumber: 1, recommendedAgeMinMonths: 2, recommendedAgeMaxMonths: 2, ageGroupLabel: "2 Months", displayName: "DTaP", abbreviation: "DTaP")
        #expect(service.status(for: dose, records: [], childAgeMonths: 5.0) == .overdue)
    }

    @Test func pendingDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(vaccineType: "dtap", doseNumber: 1, recommendedAgeMinMonths: 2, recommendedAgeMaxMonths: 4, ageGroupLabel: "2 Months", displayName: "DTaP", abbreviation: "DTaP")
        #expect(service.status(for: dose, records: [], childAgeMonths: 3.0) == .pending)
    }

    @Test func upcomingDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(vaccineType: "mmr", doseNumber: 1, recommendedAgeMinMonths: 12, recommendedAgeMaxMonths: 15, ageGroupLabel: "12-15 Months", displayName: "MMR", abbreviation: "MMR")
        #expect(service.status(for: dose, records: [], childAgeMonths: 6.0) == .upcoming)
    }

    @Test func progressCounts() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")!
        let records = [
            VaccinationRecord(childId: "c1", vaccineType: "hepB", doseNumber: 1, dateAdministered: Date()),
            VaccinationRecord(childId: "c1", vaccineType: "rsv", doseNumber: 1, dateAdministered: Date()),
        ]
        let progress = service.progress(for: schedule, records: records)
        #expect(progress.completed == 2)
        #expect(progress.total == schedule.doses.count)
    }

    @Test func childAgeAtDate() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let vacDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 18))!
        #expect(VaccinationScheduleService.ageString(from: birthday, to: vacDate) == "2m 3d")
    }

    @Test func childAgeInMonths() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 15))!
        #expect(VaccinationScheduleService.ageInMonths(from: birthday, to: now) == 6.0)
    }
}
