import Testing
import Foundation
@testable import GentleGuardian

/// Tests for ActiveChildState.
@Suite("ActiveChildState Tests")
struct ActiveChildStateTests {

    @Test("Initial state has no children")
    func initialState() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(state.children.isEmpty)
        #expect(state.activeChild == nil)
        #expect(state.hasChildren == false)
        #expect(state.hasMultipleChildren == false)
    }

    @Test("updateChildren auto-selects first child")
    func autoSelect() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let child = Child(
            id: "child-1",
            firstName: "Emma",
            birthday: Date(),
            sex: .female,
            syncCode: "ABC123"
        )

        state.updateChildren([child])

        #expect(state.activeChildId == "child-1")
        #expect(state.activeChild?.firstName == "Emma")
        #expect(state.hasChildren == true)
    }

    @Test("updateChildren preserves valid selection")
    func preserveSelection() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let child1 = Child(id: "c1", firstName: "Emma", birthday: Date(), sex: .female, syncCode: "A")
        let child2 = Child(id: "c2", firstName: "Liam", birthday: Date(), sex: .male, syncCode: "B")

        state.updateChildren([child1, child2])
        state.selectChild("c2")

        // Update with same children - selection should persist
        state.updateChildren([child1, child2])

        #expect(state.activeChildId == "c2")
    }

    @Test("updateChildren resets invalid selection")
    func resetInvalidSelection() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let child1 = Child(id: "c1", firstName: "Emma", birthday: Date(), sex: .female, syncCode: "A")

        state.updateChildren([child1])
        state.activeChildId = "nonexistent"

        // Update triggers auto-selection
        state.updateChildren([child1])

        #expect(state.activeChildId == "c1")
    }

    @Test("selectChild only works for known children")
    func selectKnownChild() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let child = Child(id: "c1", firstName: "Emma", birthday: Date(), sex: .female, syncCode: "A")

        state.updateChildren([child])
        state.selectChild("unknown-id")

        // Should not change since "unknown-id" is not in the list
        #expect(state.activeChildId == "c1")
    }

    @Test("hasMultipleChildren")
    func multipleChildren() {
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let child1 = Child(id: "c1", firstName: "Emma", birthday: Date(), sex: .female, syncCode: "A")
        let child2 = Child(id: "c2", firstName: "Liam", birthday: Date(), sex: .male, syncCode: "B")

        state.updateChildren([child1])
        #expect(state.hasMultipleChildren == false)

        state.updateChildren([child1, child2])
        #expect(state.hasMultipleChildren == true)
    }
}
