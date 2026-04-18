import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the OtherEvent model, verifying initialization,
/// Ditto serialization round-trips, and summary formatting.
@MainActor
struct OtherEventTests {

    // MARK: - Initialization Tests

    @Test("Init with defaults sets expected values")
    func initWithDefaults() {
        let event = OtherEvent(childId: "child-1", name: "Massage")

        #expect(!event.id.isEmpty)
        #expect(event.childId == "child-1")
        #expect(event.name == "Massage")
        #expect(event.durationMinutes == nil)
        #expect(event.description == "")
        #expect(event.isArchived == false)
        #expect(!event.date.isEmpty)
    }

    @Test("Init with all fields preserves values")
    func initWithAllFields() {
        let now = Date()
        let event = OtherEvent(
            id: "test-id",
            childId: "child-1",
            name: "Music class",
            timestamp: now,
            date: "2026-04-18",
            durationMinutes: 45,
            description: "Piano practice",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )

        #expect(event.id == "test-id")
        #expect(event.childId == "child-1")
        #expect(event.name == "Music class")
        #expect(event.timestamp == now)
        #expect(event.date == "2026-04-18")
        #expect(event.durationMinutes == 45)
        #expect(event.description == "Piano practice")
        #expect(event.isArchived == false)
    }

    // MARK: - Ditto Serialization Round-Trip Tests

    @Test("toDittoDocument and init(from:) round-trip preserves all fields")
    func dittoRoundTrip() {
        let now = Date()
        let original = OtherEvent(
            id: "round-trip-id",
            childId: "child-1",
            name: "Swimming",
            timestamp: now,
            durationMinutes: 30,
            description: "Swim lesson at the pool",
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )

        let doc = original.toDittoDocument()
        let restored = OtherEvent(from: doc)

        #expect(restored.id == original.id)
        #expect(restored.childId == original.childId)
        #expect(restored.name == original.name)
        #expect(restored.date == original.date)
        #expect(restored.durationMinutes == original.durationMinutes)
        #expect(restored.description == original.description)
        #expect(restored.isArchived == original.isArchived)
    }

    @Test("toDittoDocument maps _id correctly")
    func dittoDocumentIdMapping() {
        let event = OtherEvent(id: "my-id", childId: "child-1", name: "Test")
        let doc = event.toDittoDocument()

        #expect(doc["_id"] as? String == "my-id")
    }

    @Test("init(from:) handles missing optional fields gracefully")
    func initFromDocumentMissingOptionals() {
        let doc: [String: Any?] = [
            "_id": "doc-id",
            "childId": "child-1",
            "name": "Yoga",
        ]
        let event = OtherEvent(from: doc)

        #expect(event.id == "doc-id")
        #expect(event.childId == "child-1")
        #expect(event.name == "Yoga")
        #expect(event.durationMinutes == nil)
        #expect(event.description == "")
        #expect(event.isArchived == false)
    }

    // MARK: - Summary Tests

    @Test("Summary shows name with duration when duration is present")
    func summaryWithDuration() {
        let event = OtherEvent(childId: "child-1", name: "Massage", durationMinutes: 20)

        #expect(event.summary == "Massage - 20 min")
    }

    @Test("Summary shows name only when no duration")
    func summaryWithoutDuration() {
        let event = OtherEvent(childId: "child-1", name: "Doctor visit")

        #expect(event.summary == "Doctor visit")
    }
}
