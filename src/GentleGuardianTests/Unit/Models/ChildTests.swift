import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the Child model's initialization and serialization.
@Suite("Child Model Tests")
struct ChildTests {

    @Test("Child initializes with default values")
    func childDefaultInit() {
        let child = Child(
            firstName: "Emma",
            birthday: Date(),
            sex: .female,
            syncCode: "ABC123"
        )

        #expect(child.firstName == "Emma")
        #expect(child.sex == .female)
        #expect(child.syncCode == "ABC123")
        #expect(child.dayStartHour == AppConstants.defaultDayStartHour)
        #expect(child.dayEndHour == AppConstants.defaultDayEndHour)
        #expect(child.isArchived == false)
        #expect(!child.id.isEmpty)
    }

    @Test("Child round-trips through Ditto document")
    func childDittoRoundTrip() {
        let original = Child(
            id: "test-id-123",
            firstName: "Liam",
            birthday: Date(timeIntervalSince1970: 1700000000),
            sex: .male,
            prematurityWeeks: 4,
            prematurityStatus: .latePreterm,
            syncCode: "XYZ789",
            dayStartHour: 7,
            dayEndHour: 21,
            createdAt: Date(timeIntervalSince1970: 1699000000),
            updatedAt: Date(timeIntervalSince1970: 1699000000),
            isArchived: false,
            createdByDeviceId: "device-abc"
        )

        let doc = original.toDittoDocument()
        let restored = Child(from: doc)

        #expect(restored.id == "test-id-123")
        #expect(restored.firstName == "Liam")
        #expect(restored.sex == .male)
        #expect(restored.prematurityWeeks == 4)
        #expect(restored.prematurityStatus == .latePreterm)
        #expect(restored.syncCode == "XYZ789")
        #expect(restored.dayStartHour == 7)
        #expect(restored.dayEndHour == 21)
        #expect(restored.isArchived == false)
        #expect(restored.createdByDeviceId == "device-abc")
    }

    @Test("Child initializes from incomplete document with defaults")
    func childFromIncompleteDocument() {
        let doc: [String: Any?] = [
            "_id": "partial-id",
            "firstName": "Nora"
        ]

        let child = Child(from: doc)

        #expect(child.id == "partial-id")
        #expect(child.firstName == "Nora")
        #expect(child.sex == .other) // default
        #expect(child.syncCode == "")
        #expect(child.dayStartHour == AppConstants.defaultDayStartHour)
        #expect(child.isArchived == false)
    }

    @Test("Child age string formats correctly")
    func childAgeString() {
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date())!

        let child = Child(
            firstName: "Test",
            birthday: sixMonthsAgo,
            sex: .female,
            syncCode: "TST123"
        )

        #expect(child.ageString.contains("m"))
    }
}
