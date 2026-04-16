import Testing
import Foundation
@testable import GentleGuardian

/// Tests for LogDiaperViewModel covering conditional field validation for poop vs pee.
@MainActor
struct LogDiaperViewModelTests {

    // MARK: - Helpers

    private func makeSUT() -> (LogDiaperViewModel, MockDiaperRepository) {
        let mockRepo = MockDiaperRepository()
        let viewModel = LogDiaperViewModel(
            childId: "child-1",
            diaperRepository: mockRepo
        )
        return (viewModel, mockRepo)
    }

    // MARK: - Validation Tests

    @Test("Diaper form is always valid")
    func diaperFormAlwaysValid() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.isFormValid)
    }

    @Test("Poop type shows poop fields")
    func poopTypeShowsPoopFields() {
        let (viewModel, _) = makeSUT()
        viewModel.diaperType = .poop

        #expect(viewModel.showPoopFields)
    }

    @Test("Pee type hides poop fields")
    func peeTypeHidesPoopFields() {
        let (viewModel, _) = makeSUT()
        viewModel.diaperType = .pee

        #expect(!viewModel.showPoopFields)
    }

    // MARK: - Save Tests

    @Test("Save pee event excludes color and consistency")
    func savePeeExcludesPoopFields() async {
        let (viewModel, mockRepo) = makeSUT()
        viewModel.diaperType = .pee
        viewModel.quantity = .medium
        // Set color/consistency even though they should be ignored for pee
        viewModel.color = .green
        viewModel.consistency = .loose

        await viewModel.save()

        #expect(viewModel.didSave)
        #expect(mockRepo.insertedEvents.count == 1)

        let event = mockRepo.insertedEvents.first!
        #expect(event.childId == "child-1")
        #expect(event.type == .pee)
        #expect(event.quantity == .medium)
        #expect(event.color == nil)
        #expect(event.consistency == nil)
    }

    @Test("Save poop event includes color and consistency")
    func savePoopIncludesPoopFields() async {
        let (viewModel, mockRepo) = makeSUT()
        viewModel.diaperType = .poop
        viewModel.quantity = .big
        viewModel.color = .yellow
        viewModel.consistency = .loose

        await viewModel.save()

        #expect(viewModel.didSave)
        let event = mockRepo.insertedEvents.first!
        #expect(event.type == .poop)
        #expect(event.quantity == .big)
        #expect(event.color == .yellow)
        #expect(event.consistency == .loose)
    }

    @Test("Save includes notes when provided")
    func saveIncludesNotes() async {
        let (viewModel, mockRepo) = makeSUT()
        viewModel.diaperType = .pee
        viewModel.notes = "Rash noticed"

        await viewModel.save()

        let event = mockRepo.insertedEvents.first!
        #expect(event.notes == "Rash noticed")
    }

    @Test("Save trims whitespace from notes")
    func saveTrimsNotes() async {
        let (viewModel, mockRepo) = makeSUT()
        viewModel.notes = "  Some note  "

        await viewModel.save()

        let event = mockRepo.insertedEvents.first!
        #expect(event.notes == "Some note")
    }

    @Test("Save failure shows error message")
    func saveFailureShowsError() async {
        let (viewModel, mockRepo) = makeSUT()
        mockRepo.shouldThrow = true

        await viewModel.save()

        #expect(!viewModel.didSave)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Default quantity is medium")
    func defaultQuantityIsMedium() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.quantity == .medium)
    }

    @Test("Default type is pee")
    func defaultTypeIsPee() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.diaperType == .pee)
    }

    @Test("Save poop with all diaper colors")
    func savePoopWithAllColors() async {
        for diaperColor in DiaperColor.allCases {
            let (viewModel, mockRepo) = makeSUT()
            viewModel.diaperType = .poop
            viewModel.color = diaperColor

            await viewModel.save()

            let event = mockRepo.insertedEvents.first!
            #expect(event.color == diaperColor)
        }
    }

    @Test("Save poop with all consistencies")
    func savePoopWithAllConsistencies() async {
        for consistency in DiaperConsistency.allCases {
            let (viewModel, mockRepo) = makeSUT()
            viewModel.diaperType = .poop
            viewModel.consistency = consistency

            await viewModel.save()

            let event = mockRepo.insertedEvents.first!
            #expect(event.consistency == consistency)
        }
    }

    @Test("Timestamp defaults to approximately now")
    func timestampDefaultsToNow() {
        let (viewModel, _) = makeSUT()

        let diff = abs(viewModel.timestamp.timeIntervalSinceNow)
        #expect(diff < 5.0)
    }
}
