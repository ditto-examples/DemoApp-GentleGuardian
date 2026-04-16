import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the ActivityEvent model's initialization and serialization.
@Suite("ActivityEvent Model Tests")
struct ActivityEventTests {

    @Test("Activity event initializes with duration")
    func activityWithDuration() {
        let event = ActivityEvent(
            childId: "child-1",
            activityType: .tummyTime,
            durationMinutes: 15,
            description: "Good session"
        )

        #expect(event.activityType == .tummyTime)
        #expect(event.durationMinutes == 15)
        #expect(event.description == "Good session")
    }

    @Test("Activity event initializes without duration")
    func activityWithoutDuration() {
        let event = ActivityEvent(
            childId: "child-1",
            activityType: .brushTeeth
        )

        #expect(event.activityType == .brushTeeth)
        #expect(event.durationMinutes == nil)
    }

    @Test("ActivityEvent round-trips through Ditto document")
    func activityDittoRoundTrip() {
        let original = ActivityEvent(
            id: "activity-1",
            childId: "child-1",
            activityType: .bath,
            durationMinutes: 20,
            description: "Evening bath"
        )

        let doc = original.toDittoDocument()
        let restored = ActivityEvent(from: doc)

        #expect(restored.id == "activity-1")
        #expect(restored.activityType == .bath)
        #expect(restored.durationMinutes == 20)
        #expect(restored.description == "Evening bath")
    }

    @Test("Activity summary with duration")
    func activitySummaryWithDuration() {
        let event = ActivityEvent(
            childId: "child-1",
            activityType: .tummyTime,
            durationMinutes: 10
        )

        #expect(event.summary == "Tummy Time - 10 min")
    }

    @Test("Activity summary without duration")
    func activitySummaryWithoutDuration() {
        let event = ActivityEvent(
            childId: "child-1",
            activityType: .brushTeeth
        )

        #expect(event.summary == "Brush Teeth")
    }

    @Test("ActivityType hasDuration property")
    func activityTypeHasDuration() {
        #expect(ActivityType.bath.hasDuration == true)
        #expect(ActivityType.tummyTime.hasDuration == true)
        #expect(ActivityType.brushTeeth.hasDuration == false)
    }
}
