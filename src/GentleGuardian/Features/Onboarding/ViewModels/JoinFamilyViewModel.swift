import Foundation
import Observation

// MARK: - Repository Protocol

/// Protocol defining the child-lookup interface needed by JoinFamilyViewModel.
@MainActor
protocol JoinFamilyChildDataSource: AnyObject {
    func findBySyncCode(syncCode: String) async -> Child?
}

extension ChildRepository: JoinFamilyChildDataSource {}

/// ViewModel managing the "Join Family" flow where a user enters a sync code
/// to discover and join an existing child from another device.
@Observable
@MainActor
final class JoinFamilyViewModel {

    // MARK: - Form State

    /// The sync code entered by the user (auto-uppercased).
    var syncCode: String = "" {
        didSet {
            // Auto-uppercase and limit to allowed characters
            let uppercased = syncCode.uppercased()
            let allowed = CharacterSet(charactersIn: AppConstants.syncCodeCharacters)
            let filtered = String(uppercased.unicodeScalars.filter { allowed.contains($0) })
            let limited = String(filtered.prefix(AppConstants.syncCodeLength))
            if syncCode != limited {
                syncCode = limited
            }
        }
    }

    // MARK: - UI State

    /// Whether a search/validation operation is in progress.
    var isSearching: Bool = false

    /// Error message to display, if any.
    var errorMessage: String?

    /// Whether a child was successfully found and joined.
    var didComplete: Bool = false

    /// The found child, displayed briefly before completing.
    var foundChild: Child?

    /// Seconds remaining before the search times out.
    var searchTimeoutSeconds: Int = 0

    // MARK: - Validation

    /// Whether the sync code is valid for submission.
    var isSyncCodeValid: Bool {
        SyncCodeGenerator.isValid(syncCode)
    }

    /// Validation message for the sync code field.
    var syncCodeValidationMessage: String? {
        guard !syncCode.isEmpty else { return nil }
        if syncCode.count < AppConstants.syncCodeLength {
            return "\(AppConstants.syncCodeLength - syncCode.count) more characters needed"
        }
        if !isSyncCodeValid {
            return "Invalid code format"
        }
        return nil
    }

    // MARK: - Dependencies

    private let childRepository: any JoinFamilyChildDataSource
    private let activeChildState: ActiveChildState
    private let dittoManager: (any DittoManaging)?

    /// Task tracking the search timeout.
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(childRepository: any JoinFamilyChildDataSource, activeChildState: ActiveChildState, dittoManager: (any DittoManaging)? = nil) {
        self.childRepository = childRepository
        self.activeChildState = activeChildState
        self.dittoManager = dittoManager
    }

    // MARK: - Actions

    /// Validates the sync code and begins searching for the child.
    ///
    /// This triggers a Ditto subscription for the sync code and then polls
    /// the ChildRepository for the arriving document.
    func validateAndSearch() async {
        guard isSyncCodeValid else { return }

        isSearching = true
        errorMessage = nil
        foundChild = nil
        searchTimeoutSeconds = 30

        // Subscribe via Ditto to start receiving the child document
        if let dittoManager {
            await dittoManager.subscribeToChildBySyncCode(syncCode: syncCode)
        }

        // Poll for the child document with a timeout
        searchTask = Task { [weak self] in
            guard let self else { return }
            let maxAttempts = 30
            for attempt in 0..<maxAttempts {
                if Task.isCancelled { break }

                // Check for the child
                let child = await self.childRepository.findBySyncCode(syncCode: self.syncCode)

                if let child {
                    await self.handleFoundChild(child)
                    return
                }

                self.searchTimeoutSeconds = maxAttempts - attempt - 1
                try? await Task.sleep(for: .seconds(1))
            }

            // Timeout
            if !Task.isCancelled {
                self.isSearching = false
                self.errorMessage = "Could not find a child with this sync code. Make sure the other device is nearby and syncing."
            }
        }
    }

    /// Cancels an in-progress search.
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
        searchTimeoutSeconds = 0
    }

    // MARK: - Private Methods

    private func handleFoundChild(_ child: Child) async {
        foundChild = child

        // Subscribe to all child data
        if let dittoManager {
            await dittoManager.subscribeToChildData(childId: child.id)
        }

        // Update active child state
        activeChildState.updateChildren(activeChildState.children + [child])
        activeChildState.selectChild(child.id)

        isSearching = false
        didComplete = true
    }
}
