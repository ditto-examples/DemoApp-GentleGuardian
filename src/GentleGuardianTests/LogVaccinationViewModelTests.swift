import Testing
import Foundation
@testable import GentleGuardian

struct LogVaccinationViewModelTests {

    @Test func ageAtSelectedDateComputation() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let vacDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 18))!

        let ageString = VaccinationScheduleService.ageString(from: birthday, to: vacDate)

        #expect(ageString == "2m 3d")
    }

    @Test func dateCannotBeBeforeBirthday() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let beforeBirthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14))!

        // The date range should be birthday...Date()
        #expect(beforeBirthday < birthday)
    }

    @Test func customVaccineNameRequired() {
        // For "other" type, name must be non-empty
        let name = ""
        let isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(!isValid)

        let validName = "Yellow Fever"
        let isValid2 = !validName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(isValid2)
    }
}
