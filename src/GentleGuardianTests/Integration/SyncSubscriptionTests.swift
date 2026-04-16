import Testing
import Foundation
@testable import GentleGuardian

/// Tests for sync subscription management using MockDittoManager.
///
/// These tests verify that the subscription lifecycle (subscribe, unsubscribe,
/// re-subscribe) works correctly through the DittoManaging protocol, ensuring
/// the correct child IDs and sync codes are tracked.
@Suite("Sync Subscription Tests")
struct SyncSubscriptionTests {

    // MARK: - Subscribe by Sync Code

    @Test("subscribeToChildBySyncCode records the sync code")
    func subscribeBySyncCode() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()  // Mark as initialized

        // When: We subscribe by sync code
        await mock.subscribeToChildBySyncCode(syncCode: "ABC123")

        // Then: The sync code should be recorded
        let syncCodes = await mock.allSubscribedSyncCodes
        #expect(syncCodes.count == 1)
        #expect(syncCodes.first == "ABC123")
    }

    @Test("subscribing with multiple sync codes records all of them")
    func subscribeMultipleSyncCodes() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        await mock.subscribeToChildBySyncCode(syncCode: "ABC123")
        await mock.subscribeToChildBySyncCode(syncCode: "XYZ789")
        await mock.subscribeToChildBySyncCode(syncCode: "DEF456")

        let syncCodes = await mock.allSubscribedSyncCodes
        #expect(syncCodes.count == 3)
        #expect(syncCodes.contains("ABC123"))
        #expect(syncCodes.contains("XYZ789"))
        #expect(syncCodes.contains("DEF456"))
    }

    // MARK: - Subscribe to Child Data

    @Test("subscribeToChildData records the child ID")
    func subscribeToChildData() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // When: We subscribe to a child's data
        await mock.subscribeToChildData(childId: "child-1")

        // Then: The child ID should be recorded
        let childIds = await mock.allSubscribedChildIds
        #expect(childIds.count == 1)
        #expect(childIds.first == "child-1")
    }

    @Test("subscribeToChildData creates subscriptions for all 6 collections conceptually")
    func subscribeCreatesMultipleSubscriptions() async throws {
        // This test verifies the DittoManager contract: subscribing to a child
        // should create subscriptions for children, feeding, diaper, health,
        // activity, and customItems collections.
        //
        // With MockDittoManager, we verify the child ID is recorded.
        // The real DittoManager creates 6 subscriptions internally.
        let mock = MockDittoManager()
        try await mock.initialize()

        await mock.subscribeToChildData(childId: "child-multi")

        let childIds = await mock.allSubscribedChildIds
        #expect(childIds.contains("child-multi"))

        // Verify the expected collection count through AppConstants
        #expect(AppConstants.Collections.all.count == 6)
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.children))
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.feeding))
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.diaper))
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.health))
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.activity))
        #expect(AppConstants.Collections.all.contains(AppConstants.Collections.customItems))
    }

    // MARK: - Unsubscribe

    @Test("unsubscribeFromChild records the child ID for unsubscription")
    func unsubscribeFromChild() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // Given: A subscribed child
        await mock.subscribeToChildData(childId: "child-to-unsub")

        // When: We unsubscribe
        await mock.unsubscribeFromChild(childId: "child-to-unsub")

        // Then: The unsubscription should be recorded
        let unsubscribed = await mock.allUnsubscribedChildIds
        #expect(unsubscribed.count == 1)
        #expect(unsubscribed.first == "child-to-unsub")
    }

    @Test("unsubscribing cancels all subscriptions for that child")
    func unsubscribeCancelsAll() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // Given: A child with subscriptions
        await mock.subscribeToChildData(childId: "child-cancel")

        // When: We unsubscribe
        await mock.unsubscribeFromChild(childId: "child-cancel")

        // Then: The child should appear in both subscribed and unsubscribed lists
        let subscribed = await mock.allSubscribedChildIds
        let unsubscribed = await mock.allUnsubscribedChildIds
        #expect(subscribed.contains("child-cancel"))
        #expect(unsubscribed.contains("child-cancel"))
    }

    // MARK: - Re-Subscribe on Launch

    @Test("re-subscribing after unsubscribe adds child ID again")
    func resubscribeAfterUnsubscribe() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // Given: Subscribe, then unsubscribe
        await mock.subscribeToChildData(childId: "child-resub")
        await mock.unsubscribeFromChild(childId: "child-resub")

        // When: Re-subscribe (simulating app relaunch)
        await mock.subscribeToChildData(childId: "child-resub")

        // Then: The child should appear twice in subscribed list
        let subscribed = await mock.allSubscribedChildIds
        let resubCount = subscribed.filter { $0 == "child-resub" }.count
        #expect(resubCount == 2, "Child should be subscribed twice (initial + re-subscribe)")
    }

    @Test("re-subscribing for multiple known children restores all subscriptions")
    func resubscribeMultipleChildren() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // Simulate app relaunch: subscribe to all known children
        let knownChildIds = ["child-A", "child-B", "child-C"]
        for childId in knownChildIds {
            await mock.subscribeToChildData(childId: childId)
        }

        let subscribed = await mock.allSubscribedChildIds
        #expect(subscribed.count == 3)
        for childId in knownChildIds {
            #expect(subscribed.contains(childId))
        }
    }

    // MARK: - Mixed Operations

    @Test("subscribe and unsubscribe interleaved correctly tracks state")
    func interleavedSubscribeUnsubscribe() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // Subscribe to two children
        await mock.subscribeToChildData(childId: "child-1")
        await mock.subscribeToChildData(childId: "child-2")

        // Unsubscribe from the first
        await mock.unsubscribeFromChild(childId: "child-1")

        let subscribed = await mock.allSubscribedChildIds
        let unsubscribed = await mock.allUnsubscribedChildIds

        #expect(subscribed.count == 2) // Both were subscribed
        #expect(unsubscribed.count == 1) // Only child-1 was unsubscribed
        #expect(unsubscribed.first == "child-1")
    }

    @Test("subscribe by sync code and then by child ID for same child")
    func subscribeSyncCodeThenChildId() async throws {
        let mock = MockDittoManager()
        try await mock.initialize()

        // First discover the child by sync code
        await mock.subscribeToChildBySyncCode(syncCode: "FAMILY")

        // Then subscribe to their full data by child ID (after discovering the child record)
        await mock.subscribeToChildData(childId: "discovered-child")

        let syncCodes = await mock.allSubscribedSyncCodes
        let childIds = await mock.allSubscribedChildIds

        #expect(syncCodes.count == 1)
        #expect(syncCodes.first == "FAMILY")
        #expect(childIds.count == 1)
        #expect(childIds.first == "discovered-child")
    }

    // MARK: - Initialization State

    @Test("mock tracks initialization state correctly")
    func mockInitializationState() async throws {
        let mock = MockDittoManager()

        // Initially not initialized
        var isInit = await mock.isInitialized
        #expect(isInit == false)

        // After initialize
        try await mock.initialize()
        isInit = await mock.isInitialized
        #expect(isInit == true)

        // After shutdown
        await mock.shutdown()
        isInit = await mock.isInitialized
        #expect(isInit == false)
    }

    @Test("mock initialization can be configured to fail")
    func mockInitializationFailure() async {
        let mock = MockDittoManager()
        await mock.setFailInitialization(true)

        do {
            try await mock.initialize()
            Issue.record("Expected initialization to fail")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock initialization failure"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Mock Helper Extensions

extension MockDittoManager {
    /// Convenience for setting shouldFailInitialization from tests.
    func setFailInitialization(_ value: Bool) {
        shouldFailInitialization = value
    }
}
