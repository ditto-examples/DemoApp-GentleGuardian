import Foundation
import DittoSwift
import os.log

/// Thread-safe actor managing the singleton Ditto instance.
///
/// Responsible for:
/// - Initializing Ditto with Online Playground identity (v5 API)
/// - Configuring transports (BLE, LAN, AWDL enabled; WebSocket disabled)
/// - Setting all collection sync scopes to SmallPeersOnly
/// - Managing per-child sync subscriptions
/// - Providing execute/registerObserver wrappers
actor DittoManager: DittoManaging {

    // MARK: - Singleton

    /// Shared instance for app-wide use.
    static let shared = DittoManager()

    // MARK: - Private Properties

    /// The Ditto SDK instance. Nil until `initialize()` is called.
    private var ditto: Ditto?

    /// Active sync subscriptions keyed by "purpose:childId".
    private var subscriptions: [String: DittoSyncSubscription] = [:]

    /// Retained presence observer to prevent Ditto from garbage-collecting it.
    private var presenceObserver: DittoObserver?

    /// Logger for Ditto operations.
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "DittoManager")

    // MARK: - DittoManaging Protocol

    var isInitialized: Bool {
        ditto != nil
    }

    func initialize() async throws {
        guard ditto == nil else {
            logger.info("Ditto already initialized, skipping.")
            return
        }

        do {
            // 1. Configure Ditto with v5 API
            let serverURL = URL(string: AppConstants.dittoServerURL)!
            let config = DittoConfig(
                databaseID: AppConstants.dittoDatabaseID,
                connect: .server(url: serverURL)
            )

            let dittoInstance = try await Ditto.open(config: config)

            // 2. Set up authentication
            dittoInstance.auth?.expirationHandler = { @Sendable expiredDitto, _ in
                expiredDitto.auth?.login(
                    token: AppConstants.dittoPlaygroundToken,
                    provider: .development
                ) { _, error in
                    if let error {
                        print("Authentication failed: \(error)")
                    }
                }
            }

            // 3. Set sync scopes to SmallPeersOnly for all collections BEFORE starting sync
            let syncScopes = Dictionary(
                uniqueKeysWithValues: AppConstants.Collections.all.map { ($0, "SmallPeersOnly") }
            )
            try await dittoInstance.store.execute(
                query: "ALTER SYSTEM SET USER_COLLECTION_SYNC_SCOPES = :syncScopes",
                arguments: ["syncScopes": syncScopes]
            )

            // 4. Start sync
            try dittoInstance.sync.start()

            self.ditto = dittoInstance
            logger.info("Ditto initialized and sync started successfully.")

            // 6. Re-subscribe for any locally known children
            await resubscribeExistingChildren()

        } catch {
            logger.error("Ditto initialization failed: \(error.localizedDescription)")
            throw DittoManagerError.initializationFailed(error.localizedDescription)
        }
    }

    func shutdown() async {
        // Cancel all subscriptions
        for (key, subscription) in subscriptions {
            subscription.cancel()
            logger.debug("Cancelled subscription: \(key)")
        }
        subscriptions.removeAll()

        // Stop sync
        ditto?.sync.stop()
        ditto = nil
        logger.info("Ditto shut down.")
    }

    @discardableResult
    func execute(query: String, arguments: [String: Any?] = [:]) async throws -> DittoQueryResult {
        guard let ditto else {
            throw DittoManagerError.notInitialized
        }

        do {
            let result = try await ditto.store.execute(
                query: query,
                arguments: arguments
            )
            return result
        } catch {
            logger.error("Query failed: \(error.localizedDescription)\nQuery: \(query)")
            throw DittoManagerError.queryFailed(error.localizedDescription)
        }
    }

    func registerObserver(
        query: String,
        arguments: [String: Any?] = [:],
        handler: @escaping @Sendable (DittoQueryResult) -> Void
    ) async throws -> DittoStoreObserver {
        guard let ditto else {
            throw DittoManagerError.notInitialized
        }

        do {
            let observer = try ditto.store.registerObserver(
                query: query,
                arguments: arguments
            ) { result in
                handler(result)
            }
            return observer
        } catch {
            logger.error("Observer registration failed: \(error.localizedDescription)\nQuery: \(query)")
            throw DittoManagerError.queryFailed(error.localizedDescription)
        }
    }

    // MARK: - Subscription Management

    func subscribeToChildData(childId: String) async {
        guard let ditto else {
            logger.warning("Cannot subscribe - Ditto not initialized.")
            return
        }

        let collectionsToSync = [
            AppConstants.Collections.children,
            AppConstants.Collections.feeding,
            AppConstants.Collections.diaper,
            AppConstants.Collections.health,
            AppConstants.Collections.activity,
            AppConstants.Collections.sleep,
            AppConstants.Collections.customItems
        ]

        for collection in collectionsToSync {
            let key = "\(collection):\(childId)"

            // Skip if already subscribed
            guard subscriptions[key] == nil else { continue }

            let query: String
            if collection == AppConstants.Collections.children {
                query = "SELECT * FROM \(collection) WHERE _id = :childId"
            } else {
                query = "SELECT * FROM \(collection) WHERE childId = :childId"
            }

            do {
                let subscription = try ditto.sync.registerSubscription(
                    query: query,
                    arguments: ["childId": childId]
                )
                subscriptions[key] = subscription
                logger.debug("Subscribed to \(collection) for child \(childId)")
            } catch {
                logger.error("Failed to subscribe to \(collection) for child \(childId): \(error.localizedDescription)")
            }
        }
    }

    func subscribeToChildBySyncCode(syncCode: String) async {
        guard let ditto else {
            logger.warning("Cannot subscribe by sync code - Ditto not initialized.")
            return
        }

        // First, subscribe to the children collection filtered by sync code
        // so we can discover the child record
        let syncCodeKey = "children:syncCode:\(syncCode)"
        if subscriptions[syncCodeKey] == nil {
            do {
                let subscription = try ditto.sync.registerSubscription(
                    query: "SELECT * FROM \(AppConstants.Collections.children) WHERE syncCode = :syncCode",
                    arguments: ["syncCode": syncCode]
                )
                subscriptions[syncCodeKey] = subscription
                logger.debug("Subscribed to children by syncCode: \(syncCode)")
            } catch {
                logger.error("Failed to subscribe by sync code: \(error.localizedDescription)")
            }
        }
    }

    func unsubscribeFromChild(childId: String) async {
        let keysToRemove = subscriptions.keys.filter { $0.hasSuffix(":\(childId)") }
        for key in keysToRemove {
            subscriptions[key]?.cancel()
            subscriptions.removeValue(forKey: key)
            logger.debug("Unsubscribed: \(key)")
        }
    }

    // MARK: - Presence

    func setPeerMetadata(displayName: String) async throws {
        guard let ditto else {
            throw DittoManagerError.notInitialized
        }
        do {
            try ditto.presence.setPeerMetadata(["displayName": displayName])
            logger.info("Peer metadata set: displayName=\(displayName)")
        } catch {
            logger.error("setPeerMetadata failed: \(error.localizedDescription)")
            throw DittoManagerError.queryFailed(error.localizedDescription)
        }
    }

    func observePresence(handler: @escaping @Sendable ([PeerInfo]) -> Void) async {
        guard let ditto else {
            logger.warning("observePresence called before Ditto initialized.")
            return
        }

        presenceObserver = ditto.presence.observe { graph in
            var peers: [PeerInfo] = []

            let local = graph.localPeer
            let localName = (local.peerMetadata["displayName"] as? String)
                ?? local.deviceName
            peers.append(PeerInfo(
                id: local.peerKey,
                displayName: localName.isEmpty ? "This Device" : localName,
                isLocal: true
            ))

            for remote in graph.remotePeers {
                let name = (remote.peerMetadata["displayName"] as? String)
                    ?? remote.deviceName
                peers.append(PeerInfo(
                    id: remote.peerKey,
                    displayName: name.isEmpty ? "Unknown Device" : name,
                    isLocal: false
                ))
            }

            handler(peers)
        }
    }

    // MARK: - Private Methods

    /// Re-subscribes for all children found in the local store.
    ///
    /// Called during initialization to restore subscriptions from a previous session.
    private func resubscribeExistingChildren() async {
        guard let ditto else { return }

        do {
            let result = try await ditto.store.execute(
                query: "SELECT * FROM \(AppConstants.Collections.children) WHERE \(QueryHelpers.notArchived)",
                arguments: [:]
            )

            for item in result.items {
                let doc = item.value
                if let childId = doc["_id"] as? String {
                    await subscribeToChildData(childId: childId)
                }
                item.dematerialize()
            }

            logger.info("Re-subscribed to \(result.items.count) existing children.")
        } catch {
            logger.error("Failed to re-subscribe existing children: \(error.localizedDescription)")
        }
    }

    /// Logs an error message (callable from non-isolated contexts).
    private func logError(_ message: String) {
        logger.error("\(message)")
    }
}
