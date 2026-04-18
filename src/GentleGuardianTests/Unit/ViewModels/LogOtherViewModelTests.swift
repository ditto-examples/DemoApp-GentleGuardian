import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the LogOtherViewModel, verifying form validation,
/// duration parsing, save behavior, and past name loading.
@MainActor
struct LogOtherViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(
        childId: String = "child-1",
        otherRepo: MockOtherEventRepository? = nil
    ) -> (LogOtherViewModel, MockOtherEventRepository) {
        let repo = otherRepo ?? MockOtherEventRepository()
        let vm = LogOtherViewModel(childId: childId, otherEventRepository: repo)
        return (vm, repo)
    }

    // MARK: - Validation Tests

    @Test("Form is invalid when name is empty")
    func formInvalidWhenNameEmpty() {
        let (vm, _) = makeViewModel()
        vm.name = ""

        #expect(!vm.isFormValid)
    }

    @Test("Form is invalid when name is whitespace only")
    func formInvalidWhenNameWhitespace() {
        let (vm, _) = makeViewModel()
        vm.name = "   "

        #expect(!vm.isFormValid)
    }

    @Test("Form is valid when name has content")
    func formValidWhenNameHasContent() {
        let (vm, _) = makeViewModel()
        vm.name = "Massage"

        #expect(vm.isFormValid)
    }

    // MARK: - Duration Parsing Tests

    @Test("Duration value is nil when string is empty")
    func durationValueNilWhenEmpty() {
        let (vm, _) = makeViewModel()
        vm.durationMinutes = ""

        #expect(vm.durationValue == nil)
    }

    @Test("Duration value parses valid integer string")
    func durationValueParsesInt() {
        let (vm, _) = makeViewModel()
        vm.durationMinutes = "30"

        #expect(vm.durationValue == 30)
    }

    @Test("Duration value is nil for non-numeric string")
    func durationValueNilForNonNumeric() {
        let (vm, _) = makeViewModel()
        vm.durationMinutes = "abc"

        #expect(vm.durationValue == nil)
    }

    // MARK: - Save Tests

    @Test("Save succeeds and sets didSave to true")
    func saveSuccess() async {
        let (vm, repo) = makeViewModel()
        vm.name = "Massage"
        vm.durationMinutes = "20"
        vm.eventDescription = "Full body"

        await vm.save()

        #expect(vm.didSave == true)
        #expect(vm.errorMessage == nil)
        #expect(repo.insertedEvents.count == 1)
        #expect(repo.insertedEvents.first?.name == "Massage")
        #expect(repo.insertedEvents.first?.durationMinutes == 20)
        #expect(repo.insertedEvents.first?.description == "Full body")
    }

    @Test("Save trims whitespace from name and description")
    func saveTrimmedValues() async {
        let (vm, repo) = makeViewModel()
        vm.name = "  Massage  "
        vm.eventDescription = "  Some notes  "

        await vm.save()

        #expect(vm.didSave == true)
        #expect(repo.insertedEvents.first?.name == "Massage")
        #expect(repo.insertedEvents.first?.description == "Some notes")
    }

    @Test("Save does nothing when form is invalid")
    func saveSkippedWhenInvalid() async {
        let (vm, repo) = makeViewModel()
        vm.name = ""

        await vm.save()

        #expect(vm.didSave == false)
        #expect(repo.insertedEvents.isEmpty)
    }

    @Test("Save sets error message on failure")
    func saveFailure() async {
        let repo = MockOtherEventRepository()
        repo.shouldThrow = true
        let (vm, _) = makeViewModel(otherRepo: repo)
        vm.name = "Massage"

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Past Names Tests

    @Test("loadPastNames populates pastNames array")
    func loadPastNames() async {
        let repo = MockOtherEventRepository()
        repo.mockDistinctNames = ["Massage", "Music class", "Swimming"]
        let (vm, _) = makeViewModel(otherRepo: repo)

        await vm.loadPastNames()

        #expect(vm.pastNames == ["Massage", "Music class", "Swimming"])
        #expect(repo.distinctNamesCalled == "child-1")
    }

    @Test("loadPastNames handles error gracefully")
    func loadPastNamesError() async {
        let repo = MockOtherEventRepository()
        repo.shouldThrow = true
        let (vm, _) = makeViewModel(otherRepo: repo)

        await vm.loadPastNames()

        #expect(vm.pastNames.isEmpty)
    }

    @Test("Initial state has empty pastNames")
    func initialPastNamesEmpty() {
        let (vm, _) = makeViewModel()

        #expect(vm.pastNames.isEmpty)
    }
}
