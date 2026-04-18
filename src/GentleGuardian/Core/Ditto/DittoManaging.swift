import Foundation
import DittoSwift

/// Errors that can occur during Ditto operations.
enum DittoManagerError: Error, LocalizedError, Sendable {
    case notInitialized
    case initializationFailed(String)
    case queryFailed(String)
    case subscriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            "Ditto has not been initialized. Call initialize() first."
        case .initializationFailed(let reason):
            "Ditto initialization failed: \(reason)"
        case .queryFailed(let reason):
            "Ditto query failed: \(reason)"
        case .subscriptionFailed(let reason):
            "Ditto subscription failed: \(reason)"
        }
    }
}

/// Lightweight, Sendable representation of a Ditto peer for crossing actor boundaries.
struct PeerInfo: Sendable, Identifiable {
    /// The Ditto peerKey — unique identifier for this peer's session.
    let id: String
    /// Display name from peer metadata, falling back to device name.
    let displayName: String
    /// True for the local device's own peer entry.
    let isLocal: Bool
}

/// Protocol defining the interface for Ditto database operations.
///
/// Enables mock injection for testing by abstracting the Ditto SDK behind
/// a protocol. All methods are async to support the actor-based implementation.
protocol DittoManaging: Sendable {

    /// Whether Ditto has been successfully initialized and is ready for operations.
    var isInitialized: Bool { get async }

    /// Initializes the Ditto instance with configuration and starts sync.
    ///
    /// This must be called once at app startup before any other operations.
    /// - Throws: `DittoManagerError.initializationFailed` if setup fails.
    func initialize() async throws

    /// Gracefully shuts down the Ditto instance and cancels all subscriptions.
    func shutdown() async

    /// Executes a DQL query against the local Ditto store.
    ///
    /// - Parameters:
    ///   - query: A DQL query string (SELECT, INSERT, UPDATE, DELETE, EVICT, or ALTER SYSTEM).
    ///   - arguments: Named parameters to bind into the query.
    /// - Returns: A `DittoQueryResult` containing the results of the query.
    /// - Throws: `DittoManagerError.queryFailed` if execution fails.
    @discardableResult
    func execute(query: String, arguments: [String: Any?]) async throws -> DittoQueryResult

    /// Registers a live query observer that fires whenever matching documents change.
    ///
    /// - Parameters:
    ///   - query: A DQL SELECT query string.
    ///   - arguments: Named parameters to bind into the query.
    ///   - handler: A callback invoked on each change with the updated `DittoQueryResult`.
    /// - Returns: A `DittoStoreObserver` handle. Retain this to keep the observer alive;
    ///            call `.cancel()` to stop observing.
    /// - Throws: `DittoManagerError.queryFailed` if registration fails.
    func registerObserver(
        query: String,
        arguments: [String: Any?],
        handler: @escaping @Sendable (DittoQueryResult) -> Void
    ) async throws -> DittoStoreObserver

    /// Subscribes to sync data for a specific child across all event collections.
    ///
    /// This creates sync subscriptions so that data for the given child is
    /// replicated from other peers.
    ///
    /// - Parameter childId: The child's unique identifier.
    func subscribeToChildData(childId: String) async

    /// Subscribes to a child's data using their sync code.
    ///
    /// Used when joining an existing child from another device. First finds the
    /// child by sync code, then subscribes to all their event data.
    ///
    /// - Parameter syncCode: The 6-character alphanumeric sync code.
    func subscribeToChildBySyncCode(syncCode: String) async

    /// Removes all sync subscriptions for a specific child.
    ///
    /// - Parameter childId: The child's unique identifier.
    func unsubscribeFromChild(childId: String) async

    /// Sets peer metadata on the local Ditto peer.
    ///
    /// Other devices in the mesh network will see this metadata via their
    /// presence observers. Typically called after initialization and whenever
    /// the caregiver's display name changes.
    ///
    /// - Parameter displayName: The caregiver's name to broadcast.
    func setPeerMetadata(displayName: String) async throws

    /// Registers a continuous presence observer that fires on every peer graph change.
    ///
    /// `DittoManager` retains the observer internally to prevent garbage collection.
    /// The handler is dispatched on Ditto's internal thread; callers must hop to
    /// `@MainActor` if they need to update SwiftUI state.
    ///
    /// - Parameter handler: Called with a complete snapshot of all peers (local + remote).
    func observePresence(handler: @escaping @Sendable ([PeerInfo]) -> Void) async
}

/// Convenience overload allowing calls without arguments.
extension DittoManaging {
    @discardableResult
    func execute(query: String) async throws -> DittoQueryResult {
        try await execute(query: query, arguments: [:])
    }
}
