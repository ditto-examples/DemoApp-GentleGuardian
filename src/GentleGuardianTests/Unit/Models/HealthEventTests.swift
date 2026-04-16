import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the HealthEvent model's initialization and serialization.
@Suite("HealthEvent Model Tests")
struct HealthEventTests {

    @Test("Medicine event initializes correctly")
    func medicineInit() {
        let event = HealthEvent(
            childId: "child-1",
            type: .medicine,
            medicineName: "Tylenol",
            medicineQuantity: 2.5,
            medicineQuantityUnit: .ml
        )

        #expect(event.type == .medicine)
        #expect(event.medicineName == "Tylenol")
        #expect(event.medicineQuantity == 2.5)
        #expect(event.medicineQuantityUnit == .ml)
    }

    @Test("Temperature event initializes correctly")
    func temperatureInit() {
        let event = HealthEvent(
            childId: "child-1",
            type: .temperature,
            temperatureValue: 98.6,
            temperatureUnit: .fahrenheit
        )

        #expect(event.type == .temperature)
        #expect(event.temperatureValue == 98.6)
        #expect(event.temperatureUnit == .fahrenheit)
    }

    @Test("Growth event initializes correctly")
    func growthInit() {
        let event = HealthEvent(
            childId: "child-1",
            type: .growth,
            heightValue: 22.5,
            heightUnit: .inches,
            weightValue: 12.3,
            weightUnit: .lb
        )

        #expect(event.type == .growth)
        #expect(event.heightValue == 22.5)
        #expect(event.heightUnit == .inches)
        #expect(event.weightValue == 12.3)
        #expect(event.weightUnit == .lb)
    }

    @Test("HealthEvent round-trips through Ditto document")
    func healthDittoRoundTrip() {
        let original = HealthEvent(
            id: "health-1",
            childId: "child-1",
            type: .medicine,
            medicineName: "Ibuprofen",
            medicineQuantity: 1.5,
            medicineQuantityUnit: .tsp,
            notes: "For fever"
        )

        let doc = original.toDittoDocument()
        let restored = HealthEvent(from: doc)

        #expect(restored.id == "health-1")
        #expect(restored.type == .medicine)
        #expect(restored.medicineName == "Ibuprofen")
        #expect(restored.medicineQuantity == 1.5)
        #expect(restored.medicineQuantityUnit == .tsp)
        #expect(restored.notes == "For fever")
    }

    @Test("HealthEvent summary for medicine")
    func medicineSummary() {
        let event = HealthEvent(
            childId: "child-1",
            type: .medicine,
            medicineName: "Tylenol",
            medicineQuantity: 2.5,
            medicineQuantityUnit: .ml
        )

        #expect(event.summary == "Tylenol - 2.5 mL")
    }

    @Test("HealthEvent summary for temperature")
    func temperatureSummary() {
        let event = HealthEvent(
            childId: "child-1",
            type: .temperature,
            temperatureValue: 99.1,
            temperatureUnit: .fahrenheit
        )

        #expect(event.summary.contains("99.1"))
        #expect(event.summary.contains("F"))
    }
}
