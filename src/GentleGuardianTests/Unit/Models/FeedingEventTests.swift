import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the FeedingEvent model's initialization and serialization.
@Suite("FeedingEvent Model Tests")
struct FeedingEventTests {

    @Test("Bottle feeding initializes correctly")
    func bottleFeedingInit() {
        let event = FeedingEvent(
            childId: "child-1",
            type: .bottle,
            bottleQuantity: 4.5,
            bottleQuantityUnit: .oz,
            formulaType: "Similac"
        )

        #expect(event.type == .bottle)
        #expect(event.bottleQuantity == 4.5)
        #expect(event.bottleQuantityUnit == .oz)
        #expect(event.formulaType == "Similac")
        #expect(event.breastSide == nil)
        #expect(event.solidType == nil)
    }

    @Test("Breast feeding initializes correctly")
    func breastFeedingInit() {
        let event = FeedingEvent(
            childId: "child-1",
            type: .breast,
            breastDurationMinutes: 15,
            breastSide: .left
        )

        #expect(event.type == .breast)
        #expect(event.breastDurationMinutes == 15)
        #expect(event.breastSide == .left)
    }

    @Test("Solid feeding initializes correctly")
    func solidFeedingInit() {
        let event = FeedingEvent(
            childId: "child-1",
            type: .solid,
            solidType: "Banana",
            solidQuantity: 2.0,
            solidQuantityUnit: .tbsp
        )

        #expect(event.type == .solid)
        #expect(event.solidType == "Banana")
        #expect(event.solidQuantity == 2.0)
        #expect(event.solidQuantityUnit == .tbsp)
    }

    @Test("FeedingEvent round-trips through Ditto document")
    func feedingDittoRoundTrip() {
        let original = FeedingEvent(
            id: "feed-1",
            childId: "child-1",
            type: .bottle,
            bottleQuantity: 6.0,
            bottleQuantityUnit: .ml,
            formulaType: "Enfamil",
            notes: "Good feeding"
        )

        let doc = original.toDittoDocument()
        let restored = FeedingEvent(from: doc)

        #expect(restored.id == "feed-1")
        #expect(restored.childId == "child-1")
        #expect(restored.type == .bottle)
        #expect(restored.bottleQuantity == 6.0)
        #expect(restored.bottleQuantityUnit == .ml)
        #expect(restored.formulaType == "Enfamil")
        #expect(restored.notes == "Good feeding")
        #expect(restored.isArchived == false)
    }

    @Test("FeedingEvent summary for bottle")
    func bottleSummary() {
        let event = FeedingEvent(
            childId: "child-1",
            type: .bottle,
            bottleQuantity: 4.0,
            bottleQuantityUnit: .oz,
            formulaType: "Similac"
        )

        #expect(event.summary == "4.0 oz (Similac)")
    }

    @Test("FeedingEvent summary for breast")
    func breastSummary() {
        let event = FeedingEvent(
            childId: "child-1",
            type: .breast,
            breastDurationMinutes: 20,
            breastSide: .right
        )

        #expect(event.summary == "20 min Right")
    }
}
