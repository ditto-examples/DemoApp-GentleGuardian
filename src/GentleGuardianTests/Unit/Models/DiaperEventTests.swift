import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the DiaperEvent model's initialization and serialization.
@Suite("DiaperEvent Model Tests")
struct DiaperEventTests {

    @Test("Poop diaper initializes with color and consistency")
    func poopDiaperInit() {
        let event = DiaperEvent(
            childId: "child-1",
            type: .poop,
            quantity: .big,
            color: .brown,
            consistency: .solid
        )

        #expect(event.type == .poop)
        #expect(event.quantity == .big)
        #expect(event.color == .brown)
        #expect(event.consistency == .solid)
    }

    @Test("Pee diaper initializes without color and consistency")
    func peeDiaperInit() {
        let event = DiaperEvent(
            childId: "child-1",
            type: .pee,
            quantity: .medium
        )

        #expect(event.type == .pee)
        #expect(event.quantity == .medium)
        #expect(event.color == nil)
        #expect(event.consistency == nil)
    }

    @Test("DiaperEvent round-trips through Ditto document")
    func diaperDittoRoundTrip() {
        let original = DiaperEvent(
            id: "diaper-1",
            childId: "child-1",
            type: .poop,
            quantity: .little,
            color: .green,
            consistency: .loose,
            notes: "After feeding"
        )

        let doc = original.toDittoDocument()
        let restored = DiaperEvent(from: doc)

        #expect(restored.id == "diaper-1")
        #expect(restored.type == .poop)
        #expect(restored.quantity == .little)
        #expect(restored.color == .green)
        #expect(restored.consistency == .loose)
        #expect(restored.notes == "After feeding")
    }

    @Test("DiaperColor alert detection")
    func diaperColorAlert() {
        #expect(DiaperColor.red.isAlertColor == true)
        #expect(DiaperColor.black.isAlertColor == true)
        #expect(DiaperColor.white.isAlertColor == true)
        #expect(DiaperColor.brown.isAlertColor == false)
        #expect(DiaperColor.green.isAlertColor == false)
        #expect(DiaperColor.yellow.isAlertColor == false)
    }
}
