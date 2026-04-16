import Testing
import Foundation
@testable import GentleGuardian

/// Tests for RegisterChildViewModel covering form validation and successful registration.
@MainActor
struct RegisterChildViewModelTests {

    // MARK: - Helpers

    private func makeSUT() -> (RegisterChildViewModel, MockChildRepository, ActiveChildState) {
        let mockRepo = MockChildRepository()
        let activeChildState = ActiveChildState()
        let viewModel = RegisterChildViewModel(
            childRepository: mockRepo,
            activeChildState: activeChildState
        )
        return (viewModel, mockRepo, activeChildState)
    }

    // MARK: - Validation Tests

    @Test("Empty name fails validation")
    func emptyNameFailsValidation() {
        let (viewModel, _, _) = makeSUT()
        viewModel.firstName = ""
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

        #expect(!viewModel.isFormValid)
    }

    @Test("Whitespace-only name fails validation")
    func whitespaceOnlyNameFailsValidation() {
        let (viewModel, _, _) = makeSUT()
        viewModel.firstName = "   "
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

        #expect(!viewModel.isFormValid)
    }

    @Test("Future birthday fails validation")
    func futureBirthdayFailsValidation() {
        let (viewModel, _, _) = makeSUT()
        viewModel.firstName = "Theodore"
        viewModel.birthday = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        #expect(!viewModel.isFormValid)
        #expect(viewModel.birthdayValidationMessage != nil)
    }

    @Test("Valid form passes validation")
    func validFormPassesValidation() {
        let (viewModel, _, _) = makeSUT()
        viewModel.firstName = "Theodore"
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -8, to: Date())!

        #expect(viewModel.isFormValid)
        #expect(viewModel.nameValidationMessage == nil)
        #expect(viewModel.birthdayValidationMessage == nil)
    }

    // MARK: - Submission Tests

    @Test("Successful registration creates child with sync code")
    func successfulRegistrationCreatesChild() async {
        let (viewModel, mockRepo, activeChildState) = makeSUT()
        viewModel.firstName = "Theodore"
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
        viewModel.sex = .male

        await viewModel.submit()

        #expect(viewModel.didComplete)
        #expect(viewModel.errorMessage == nil)
        #expect(mockRepo.insertedChildren.count == 1)

        let child = mockRepo.insertedChildren.first!
        #expect(child.firstName == "Theodore")
        #expect(child.sex == .male)
        #expect(!child.syncCode.isEmpty)
        #expect(child.syncCode.count == AppConstants.syncCodeLength)
        #expect(activeChildState.activeChildId == child.id)
    }

    @Test("Registration trims whitespace from name")
    func registrationTrimsWhitespace() async {
        let (viewModel, mockRepo, _) = makeSUT()
        viewModel.firstName = "  Theodore  "
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -8, to: Date())!

        await viewModel.submit()

        #expect(mockRepo.insertedChildren.first?.firstName == "Theodore")
    }

    @Test("Registration with prematurity sets fields correctly")
    func registrationWithPrematurity() async {
        let (viewModel, mockRepo, _) = makeSUT()
        viewModel.firstName = "Baby"
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        viewModel.isPremature = true
        viewModel.prematurityWeeks = 34

        await viewModel.submit()

        let child = mockRepo.insertedChildren.first!
        #expect(child.prematurityWeeks == 34)
        #expect(child.prematurityStatus == .latePreterm)
    }

    @Test("Registration without prematurity has nil fields")
    func registrationWithoutPrematurity() async {
        let (viewModel, mockRepo, _) = makeSUT()
        viewModel.firstName = "Baby"
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        viewModel.isPremature = false

        await viewModel.submit()

        let child = mockRepo.insertedChildren.first!
        #expect(child.prematurityWeeks == nil)
        #expect(child.prematurityStatus == nil)
    }

    @Test("Registration failure shows error message")
    func registrationFailureShowsError() async {
        let (viewModel, mockRepo, _) = makeSUT()
        viewModel.firstName = "Baby"
        viewModel.birthday = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        mockRepo.shouldThrow = true

        await viewModel.submit()

        #expect(!viewModel.didComplete)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Invalid form does not submit")
    func invalidFormDoesNotSubmit() async {
        let (viewModel, mockRepo, _) = makeSUT()
        viewModel.firstName = ""

        await viewModel.submit()

        #expect(mockRepo.insertedChildren.isEmpty)
        #expect(!viewModel.didComplete)
    }

    // MARK: - Prematurity Status Computation

    @Test("Prematurity status computes correctly for various weeks")
    func prematurityStatusComputation() {
        let (viewModel, _, _) = makeSUT()
        viewModel.isPremature = true

        viewModel.prematurityWeeks = 25
        #expect(viewModel.computedPrematurityStatus == .extremelyPreterm)

        viewModel.prematurityWeeks = 30
        #expect(viewModel.computedPrematurityStatus == .veryPreterm)

        viewModel.prematurityWeeks = 33
        #expect(viewModel.computedPrematurityStatus == .moderatePreterm)

        viewModel.prematurityWeeks = 35
        #expect(viewModel.computedPrematurityStatus == .latePreterm)

        viewModel.prematurityWeeks = 38
        #expect(viewModel.computedPrematurityStatus == .earlyTerm)
    }

    @Test("Prematurity status is nil when not premature")
    func prematurityStatusNilWhenNotPremature() {
        let (viewModel, _, _) = makeSUT()
        viewModel.isPremature = false
        viewModel.prematurityWeeks = 30

        #expect(viewModel.computedPrematurityStatus == nil)
    }
}
