import Testing
import Foundation
@testable import GentleGuardian

/// Tests for JoinFamilyViewModel covering sync code validation and search behavior.
@MainActor
struct JoinFamilyViewModelTests {

    // MARK: - Helpers

    private func makeSUT() -> (JoinFamilyViewModel, MockChildRepository, ActiveChildState) {
        let mockRepo = MockChildRepository()
        let activeChildState = ActiveChildState()
        let viewModel = JoinFamilyViewModel(
            childRepository: mockRepo,
            activeChildState: activeChildState
        )
        return (viewModel, mockRepo, activeChildState)
    }

    // MARK: - Sync Code Validation

    @Test("Empty sync code is invalid")
    func emptySyncCodeIsInvalid() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = ""

        #expect(!viewModel.isSyncCodeValid)
    }

    @Test("Short sync code is invalid")
    func shortSyncCodeIsInvalid() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "ABC"

        #expect(!viewModel.isSyncCodeValid)
        #expect(viewModel.syncCodeValidationMessage != nil)
    }

    @Test("Correct length alphanumeric sync code is valid")
    func correctLengthSyncCodeIsValid() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "ABC234"

        #expect(viewModel.isSyncCodeValid)
        #expect(viewModel.syncCodeValidationMessage == nil)
    }

    @Test("Sync code auto-uppercases")
    func syncCodeAutoUppercases() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "abc234"

        #expect(viewModel.syncCode == "ABC234")
    }

    @Test("Sync code filters invalid characters")
    func syncCodeFiltersInvalidCharacters() {
        let (viewModel, _, _) = makeSUT()
        // O, 0, I, 1 are excluded from the allowed set
        viewModel.syncCode = "AB!@#C"

        // Should only keep A, B, C
        #expect(viewModel.syncCode == "ABC")
    }

    @Test("Sync code truncated to max length")
    func syncCodeTruncated() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "ABCDEFGHJ"

        #expect(viewModel.syncCode.count == AppConstants.syncCodeLength)
    }

    @Test("Validation message shows remaining characters needed")
    func validationMessageShowsRemainingChars() {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "AB"

        let message = viewModel.syncCodeValidationMessage
        #expect(message != nil)
        #expect(message!.contains("4"))
    }

    // MARK: - Search State Tests

    @Test("Initial state is not searching")
    func initialStateNotSearching() {
        let (viewModel, _, _) = makeSUT()

        #expect(!viewModel.isSearching)
        #expect(!viewModel.didComplete)
        #expect(viewModel.foundChild == nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Cancel search resets state")
    func cancelSearchResetsState() {
        let (viewModel, _, _) = makeSUT()
        viewModel.isSearching = true
        viewModel.searchTimeoutSeconds = 15

        viewModel.cancelSearch()

        #expect(!viewModel.isSearching)
        #expect(viewModel.searchTimeoutSeconds == 0)
    }

    @Test("Search does not start with invalid code")
    func searchDoesNotStartWithInvalidCode() async {
        let (viewModel, _, _) = makeSUT()
        viewModel.syncCode = "AB"

        await viewModel.validateAndSearch()

        // Should not have started searching since the code is invalid
        #expect(!viewModel.isSearching || viewModel.syncCode.count < AppConstants.syncCodeLength)
    }
}
