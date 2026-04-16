import Foundation
import DittoSwift
@testable import GentleGuardian

/// Error used internally by MockDittoManager when it cannot produce SDK return types.
///
/// Tests should check `executedQueries` and `registeredObservers` to verify
/// that the correct calls were made rather than relying on return values.
enum MockDittoError: Error, Equatable {
    /// Thrown by `execute()` because MockDittoManager cannot construct a real `DittoQueryResult`.
    case cannotReturnDittoQueryResult
    /// Thrown by `registerObserver()` because MockDittoManager cannot construct a real `DittoStoreObserver`.
    case cannotReturnObserver
}

/// Mock implementation of `DittoManaging` for unit testing.
///
/// Records all method calls and allows configuring return values and errors
/// to test various scenarios without a real Ditto instance.
///
/// ## Usage
///
/// **For mutation tests** (insert, update, softDelete):
/// The mock records the query and arguments in `executedQueries`, then throws
/// `MockDittoError.cannotReturnDittoQueryResult`. Tests should expect this error
/// and verify the recorded queries/arguments:
///
/// ```swift
/// do {
///     try await repo.insert(event: event)
///     Issue.record("Expected throw")
/// } catch {
///     // Verify the query was recorded correctly
///     let queries = await mock.executedQueries
///     #expect(queries.count == 1)
/// }
/// ```
///
/// **For error handling tests:**
/// Set `shouldFailQueries = true` to make `execute()` throw `mockError`
/// before recording the query.
///
/// **For observer tests:**
/// Observer registrations are recorded in `registeredObservers`. The observer
/// callbacks in repositories handle the `cannotReturnObserver` error gracefully
/// via their error logging.
actor MockDittoManager: DittoManaging {

    // MARK: - State Tracking

    /// Whether `initialize()` has been called.
    var initializeCalled = false

    /// Whether `shutdown()` has been called.
    var shutdownCalled = false

    /// All queries that have been executed via `execute(query:arguments:)`.
    var executedQueries: [(query: String, arguments: [String: Any?])] = []

    /// All observer registrations.
    var registeredObservers: [(query: String, arguments: [String: Any?])] = []

    /// Child IDs that have been subscribed to.
    var subscribedChildIds: [String] = []

    /// Sync codes that have been subscribed to.
    var subscribedSyncCodes: [String] = []

    /// Child IDs that have been unsubscribed from.
    var unsubscribedChildIds: [String] = []

    // MARK: - Configuration

    /// Set to `true` to make `initialize()` throw an error.
    var shouldFailInitialization = false

    /// Set to `true` to make `execute()` throw `mockError` before recording the call.
    var shouldFailQueries = false

    /// Documents to return from execute queries (as arrays of dictionaries).
    var mockDittoQueryResults: [[String: Any?]] = []

    /// Error to throw when configured to fail.
    var mockError = DittoManagerError.queryFailed("Mock error")

    // MARK: - DittoManaging Protocol

    var isInitialized: Bool {
        initializeCalled && !shutdownCalled
    }

    func initialize() async throws {
        if shouldFailInitialization {
            throw DittoManagerError.initializationFailed("Mock initialization failure")
        }
        initializeCalled = true
    }

    func shutdown() async {
        shutdownCalled = true
    }

    @discardableResult
    func execute(query: String, arguments: [String: Any?]) async throws -> DittoQueryResult {
        executedQueries.append((query: query, arguments: arguments))
        if shouldFailQueries {
            throw mockError
        }
        // We cannot construct a real DittoQueryResult from the Ditto SDK.
        // Tests should verify executedQueries to confirm correct queries/arguments.
        throw MockDittoError.cannotReturnDittoQueryResult
    }

    func registerObserver(
        query: String,
        arguments: [String: Any?],
        handler: @escaping @Sendable (DittoQueryResult) -> Void
    ) async throws -> DittoStoreObserver {
        registeredObservers.append((query: query, arguments: arguments))
        // We cannot construct a real DittoStoreObserver from the Ditto SDK.
        // Tests should verify registeredObservers to confirm correct queries/arguments.
        throw MockDittoError.cannotReturnObserver
    }

    func subscribeToChildData(childId: String) async {
        subscribedChildIds.append(childId)
    }

    func subscribeToChildBySyncCode(syncCode: String) async {
        subscribedSyncCodes.append(syncCode)
    }

    func unsubscribeFromChild(childId: String) async {
        unsubscribedChildIds.append(childId)
    }

    // MARK: - Test Helpers

    /// Returns the last executed query, or nil if none.
    var lastExecutedQuery: (query: String, arguments: [String: Any?])? {
        executedQueries.last
    }

    /// Returns the last registered observer, or nil if none.
    var lastRegisteredObserver: (query: String, arguments: [String: Any?])? {
        registeredObservers.last
    }

    // MARK: - Reset

    /// Resets all recorded state for a fresh test.
    func reset() {
        initializeCalled = false
        shutdownCalled = false
        executedQueries.removeAll()
        registeredObservers.removeAll()
        subscribedChildIds.removeAll()
        subscribedSyncCodes.removeAll()
        unsubscribedChildIds.removeAll()
        shouldFailInitialization = false
        shouldFailQueries = false
        mockDittoQueryResults.removeAll()
    }
}
