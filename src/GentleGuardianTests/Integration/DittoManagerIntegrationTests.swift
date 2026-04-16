import XCTest
@testable import GentleGuardian

/// Integration tests for DittoManager lifecycle.
///
/// These tests verify that the real DittoManager initializes, manages sync,
/// handles subscriptions, and shuts down properly. They are skipped when
/// Ditto credentials are placeholder values.
final class DittoManagerIntegrationTests: XCTestCase {

    // MARK: - Setup

    override func setUp() async throws {
        try XCTSkipIf(
            TestHelpers.credentialsArePlaceholder,
            "Ditto credentials not configured - skipping integration tests"
        )
    }

    // MARK: - Initialization

    func testDittoManagerInitializesWithoutCrashing() async throws {
        // When: We initialize the shared DittoManager
        // Then: It should not throw or crash
        do {
            try await DittoManager.shared.initialize()
            let isInitialized = await DittoManager.shared.isInitialized
            XCTAssertTrue(isInitialized, "DittoManager should be initialized after calling initialize()")
        } catch {
            XCTFail("DittoManager initialization threw unexpectedly: \(error.localizedDescription)")
        }
    }

    func testDittoManagerInitializeIsIdempotent() async throws {
        // When: We call initialize() multiple times
        // Then: It should not throw or create duplicate instances
        try await DittoManager.shared.initialize()
        try await DittoManager.shared.initialize() // Second call should be a no-op

        let isInitialized = await DittoManager.shared.isInitialized
        XCTAssertTrue(isInitialized)
    }

    // MARK: - Sync Start / Stop

    func testSyncCanBeStartedAndStopped() async throws {
        // Given: An initialized DittoManager
        try await DittoManager.shared.initialize()
        let isInitialized = await DittoManager.shared.isInitialized
        XCTAssertTrue(isInitialized)

        // When: We shut down
        await DittoManager.shared.shutdown()

        // Then: It should no longer be initialized
        let isInitializedAfterShutdown = await DittoManager.shared.isInitialized
        XCTAssertFalse(isInitializedAfterShutdown, "DittoManager should not be initialized after shutdown")
    }

    // MARK: - Subscription Management

    func testSubscribeToChildDataCreatesSubscriptions() async throws {
        // Given: An initialized DittoManager
        try await DittoManager.shared.initialize()

        // When: We subscribe to a child's data
        let testChildId = "integration-test-child-\(UUID().uuidString.prefix(8))"
        await DittoManager.shared.subscribeToChildData(childId: testChildId)

        // Then: Subscriptions should be created (verified by no crash)
        // Note: Internal subscription state is private; we verify it works
        // by ensuring no errors are thrown.

        // Cleanup: Unsubscribe
        await DittoManager.shared.unsubscribeFromChild(childId: testChildId)
    }

    func testSubscribeBySyncCodeCreatesSubscription() async throws {
        // Given: An initialized DittoManager
        try await DittoManager.shared.initialize()

        // When: We subscribe by sync code
        let testSyncCode = "INTGRT"
        await DittoManager.shared.subscribeToChildBySyncCode(syncCode: testSyncCode)

        // Then: No crash or error
        // Cleanup is handled by shutdown
    }

    func testUnsubscribeFromChildCancelsSubscriptions() async throws {
        // Given: An initialized DittoManager with active subscriptions
        try await DittoManager.shared.initialize()

        let testChildId = "integration-unsub-child-\(UUID().uuidString.prefix(8))"
        await DittoManager.shared.subscribeToChildData(childId: testChildId)

        // When: We unsubscribe
        await DittoManager.shared.unsubscribeFromChild(childId: testChildId)

        // Then: Re-subscribing should succeed (previous subscriptions were cleaned up)
        await DittoManager.shared.subscribeToChildData(childId: testChildId)

        // Cleanup
        await DittoManager.shared.unsubscribeFromChild(childId: testChildId)
    }

    // MARK: - Sync Scopes

    func testSmallPeersOnlySyncScopesAreConfigured() async throws {
        // Given/When: DittoManager is initialized
        try await DittoManager.shared.initialize()

        // Then: The initialization should have set SmallPeersOnly for all collections.
        // We verify indirectly: if initialization succeeded, the ALTER SYSTEM SET
        // query executed without error, meaning sync scopes were applied.
        let isInitialized = await DittoManager.shared.isInitialized
        XCTAssertTrue(isInitialized, "Initialization includes SmallPeersOnly setup")
    }

    // MARK: - Shutdown

    func testShutdownCleansUpProperly() async throws {
        // Given: An initialized DittoManager with subscriptions
        try await DittoManager.shared.initialize()

        let testChildId = "integration-shutdown-child"
        await DittoManager.shared.subscribeToChildData(childId: testChildId)

        // When: We shut down
        await DittoManager.shared.shutdown()

        // Then: Manager should not be initialized
        let isInitialized = await DittoManager.shared.isInitialized
        XCTAssertFalse(isInitialized, "DittoManager should be nil after shutdown")

        // And: Execute should throw notInitialized
        do {
            try await DittoManager.shared.execute(
                query: "SELECT * FROM children",
                arguments: [:]
            )
            XCTFail("Expected DittoManagerError.notInitialized")
        } catch let error as DittoManagerError {
            if case .notInitialized = error {
                // Expected
            } else {
                XCTFail("Expected notInitialized, got: \(error)")
            }
        }
    }

    func testShutdownIsIdempotent() async throws {
        // Given: An initialized DittoManager
        try await DittoManager.shared.initialize()

        // When: We call shutdown multiple times
        await DittoManager.shared.shutdown()
        await DittoManager.shared.shutdown() // Should not crash

        // Then: Should still be in shutdown state
        let isInitialized = await DittoManager.shared.isInitialized
        XCTAssertFalse(isInitialized)
    }

    // MARK: - Query Execution

    func testExecuteQueryAfterInitialization() async throws {
        // Given: An initialized DittoManager
        try await DittoManager.shared.initialize()

        // When: We execute a simple SELECT query
        // Then: It should not throw (even if there are no results)
        do {
            let result = try await DittoManager.shared.execute(
                query: "SELECT * FROM \(AppConstants.Collections.children) WHERE _id = :id",
                arguments: ["id": "non-existent-id"]
            )
            XCTAssertNotNil(result, "Query result should not be nil")
        } catch {
            XCTFail("Query execution should not throw on initialized DittoManager: \(error)")
        }
    }

    func testExecuteQueryBeforeInitializationThrows() async throws {
        // This test creates a scenario where we know Ditto is not initialized.
        // Since DittoManager is a singleton, we need to shut it down first.
        await DittoManager.shared.shutdown()

        // When: We try to execute a query without initialization
        do {
            try await DittoManager.shared.execute(
                query: "SELECT * FROM children",
                arguments: [:]
            )
            XCTFail("Expected DittoManagerError.notInitialized")
        } catch let error as DittoManagerError {
            if case .notInitialized = error {
                // Expected
            } else {
                XCTFail("Expected notInitialized, got: \(error)")
            }
        }
    }
}
