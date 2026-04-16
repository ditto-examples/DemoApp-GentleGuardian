import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for Child records.
///
/// Uses `@Observable` so SwiftUI views can bind directly to its published arrays.
/// All observer callbacks dispatch updates to `@MainActor` to ensure thread safety.
@Observable
@MainActor
final class ChildRepository {

    // MARK: - Published State

    /// All non-archived children, kept up-to-date by a live query observer.
    private(set) var children: [Child] = []

    /// A single observed child (used by detail/edit screens).
    private(set) var observedChild: Child?

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "ChildRepository")
    @ObservationIgnored nonisolated(unsafe) private var childrenObserver: DittoStoreObserver?
    @ObservationIgnored nonisolated(unsafe) private var singleChildObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        childrenObserver?.cancel()
        singleChildObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing all non-archived children, ordered by first name.
    func observeChildren() {
        childrenObserver?.cancel()

        // Children collection uses a simpler query since there's no childId filter
        let query = """
            SELECT * FROM \(AppConstants.Collections.children)
            WHERE \(QueryHelpers.notArchived)
            ORDER BY firstName ASC
            """

        Task {
            do {
                childrenObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: [:]
                ) { [weak self] result in
                    let parsed = result.items.map { item -> Child in
                        let doc = item.value
                        let child = Child(from: doc)
                        item.dematerialize()
                        return child
                    }
                    Task { @MainActor [weak self] in
                        self?.children = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe children: \(error.localizedDescription)")
            }
        }
    }

    /// Starts a live query observing a single child by ID.
    ///
    /// - Parameter id: The child's unique identifier.
    func observeChild(id: String) {
        singleChildObserver?.cancel()

        let query = QueryHelpers.selectById(from: AppConstants.Collections.children)

        Task {
            do {
                singleChildObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.idArgs(id)
                ) { [weak self] result in
                    let child: Child? = result.items.first.map { item in
                        let doc = item.value
                        let parsed = Child(from: doc)
                        item.dematerialize()
                        return parsed
                    }
                    Task { @MainActor [weak self] in
                        self?.observedChild = child
                    }
                }
            } catch {
                logger.error("Failed to observe child \(id): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - One-Time Queries

    /// Finds a child by their sync code.
    ///
    /// - Parameter syncCode: The 6-character alphanumeric sync code.
    /// - Returns: The matching child, or `nil` if not found.
    func findBySyncCode(syncCode: String) async -> Child? {
        do {
            let result = try await dittoManager.execute(
                query: QueryHelpers.findChildBySyncCode(),
                arguments: ["syncCode": syncCode]
            )

            guard let item = result.items.first else { return nil }
            let doc = item.value
            let child = Child(from: doc)
            item.dematerialize()
            return child
        } catch {
            logger.error("Failed to find child by sync code: \(error.localizedDescription)")
            return nil
        }
    }

    /// Returns all non-archived child IDs. Used for subscription re-registration on launch.
    ///
    /// - Returns: An array of child ID strings.
    func allChildIds() async throws -> [String] {
        let query = """
            SELECT * FROM \(AppConstants.Collections.children)
            WHERE \(QueryHelpers.notArchived)
            """

        let result = try await dittoManager.execute(
            query: query,
            arguments: [:]
        )

        return result.items.compactMap { item in
            let doc = item.value
            let id = doc["_id"] as? String
            item.dematerialize()
            return id
        }
    }

    // MARK: - Mutations

    /// Inserts a new child record using upsert semantics.
    ///
    /// - Parameter child: The child to insert.
    func insert(child: Child) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.children),
            arguments: ["document": child.toDittoDocument()]
        )
        logger.debug("Inserted child: \(child.id)")
    }

    /// Updates an existing child record using upsert semantics.
    ///
    /// - Parameter child: The child with updated fields.
    func update(child: Child) async throws {
        var updated = child
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.children),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated child: \(child.id)")
    }

    /// Soft-deletes a child by setting isArchived = true.
    ///
    /// - Parameter childId: The ID of the child to archive.
    func softDelete(childId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.children),
            arguments: QueryHelpers.softDeleteArgs(childId)
        )
        logger.debug("Soft-deleted child: \(childId)")
    }
}
