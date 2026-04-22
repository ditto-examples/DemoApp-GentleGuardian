import Testing
import Foundation
@testable import GentleGuardian

struct VaccinationRecordTests {

    @Test func roundTripSerialization() {
        let record = VaccinationRecord(
            childId: "child-1",
            vaccineType: "dtap",
            doseNumber: 1,
            dateAdministered: DateService.date(fromISO8601: "2026-05-18T10:00:00.000Z")!,
            notes: "No reaction"
        )

        let doc = record.toDittoDocument()
        let restored = VaccinationRecord(from: doc)

        #expect(restored.id == record.id)
        #expect(restored.childId == "child-1")
        #expect(restored.vaccineType == "dtap")
        #expect(restored.doseNumber == 1)
        #expect(restored.notes == "No reaction")
        #expect(restored.isArchived == false)
        #expect(restored.customVaccineName == nil)
    }

    @Test func otherVaccineWithCustomFields() {
        let record = VaccinationRecord(
            childId: "child-1",
            vaccineType: "other",
            doseNumber: 0,
            dateAdministered: Date(),
            notes: "Travel requirement",
            customVaccineName: "Yellow Fever",
            customVaccineDescription: "Required for travel to Brazil"
        )

        let doc = record.toDittoDocument()
        let restored = VaccinationRecord(from: doc)

        #expect(restored.vaccineType == "other")
        #expect(restored.doseNumber == 0)
        #expect(restored.customVaccineName == "Yellow Fever")
        #expect(restored.customVaccineDescription == "Required for travel to Brazil")
    }

    @Test func missingFieldsUseDefaults() {
        let doc: [String: Any?] = [
            "_id": "test-id",
            "childId": "child-1",
            "vaccineType": "mmr",
            "doseNumber": 1
        ]

        let record = VaccinationRecord(from: doc)

        #expect(record.id == "test-id")
        #expect(record.notes == nil)
        #expect(record.isArchived == false)
        #expect(record.customVaccineName == nil)
    }
}
