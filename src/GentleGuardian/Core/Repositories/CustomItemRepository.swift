import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for CustomItem records.
@Observable
@MainActor
final class CustomItemRepository {

    // MARK: - Published State

    /// Custom items for the currently observed child and category.
    private(set) var items: [CustomItem] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "CustomItemRepository")
    @ObservationIgnored nonisolated(unsafe) private var itemsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        itemsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing custom items for a child in a specific category.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - category: The custom item category to filter by.
    func observeItems(childId: String, category: CustomItemCategory) {
        itemsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.customItems,
            additionalWhere: "category = :category",
            orderBy: "name ASC"
        )

        var args = QueryHelpers.childArgs(childId)
        args["category"] = category.rawValue
        Task {
            do {
                itemsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: args
                ) { [weak self] result in
                    let parsed = result.items.map { item -> CustomItem in
                        let doc = item.value
                        let customItem = CustomItem(from: doc)
                        item.dematerialize()
                        return customItem
                    }
                    Task { @MainActor [weak self] in
                        self?.items = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe custom items: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new custom item using upsert semantics.
    ///
    /// - Parameter item: The custom item to insert.
    func insert(item: CustomItem) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.customItems),
            arguments: ["document": item.toDittoDocument()]
        )
        logger.debug("Inserted custom item: \(item.id)")
    }

    /// Updates an existing custom item using upsert semantics.
    ///
    /// - Parameter item: The custom item with updated fields.
    func update(item: CustomItem) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.customItems),
            arguments: ["document": item.toDittoDocument()]
        )
        logger.debug("Updated custom item: \(item.id)")
    }

    /// Soft-deletes a custom item by setting isArchived = true.
    ///
    /// - Parameter itemId: The ID of the item to archive.
    func softDelete(itemId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.customItems),
            arguments: QueryHelpers.softDeleteArgs(itemId)
        )
        logger.debug("Soft-deleted custom item: \(itemId)")
    }

    /// Soft-deletes a custom item and disposes its attachment, if any.
    ///
    /// - Parameter item: The item to delete.
    func delete(item: CustomItem) async throws {
        try await softDelete(itemId: item.id)
        if let token = item.attachmentToken, !token.isEmpty {
            await dittoManager.disposeAttachment(token: token)
        }
    }

    /// Counts non-archived items for a child in a category. Used to gate idempotent seeding.
    ///
    /// - Parameters:
    ///   - childId: Child to scope the query.
    ///   - category: Category to filter by.
    /// - Returns: The count of matching items.
    func count(childId: String, category: CustomItemCategory) async throws -> Int {
        let query = """
        SELECT * FROM \(AppConstants.Collections.customItems)
        WHERE childId = :childId AND category = :category AND \(QueryHelpers.notArchived)
        LIMIT 1
        """
        let result = try await dittoManager.execute(
            query: query,
            arguments: ["childId": childId, "category": category.rawValue]
        )
        return result.items.count
    }

    /// Inserts a list of items only if no non-archived items already exist for that
    /// child + category. Idempotent: safe to call repeatedly.
    ///
    /// - Parameters:
    ///   - names: Display names for the new items.
    ///   - childId: Owning child.
    ///   - category: Category to insert under.
    ///   - isSeeded: Whether to mark these items as seeded.
    func bulkInsertIfEmpty(
        names: [String],
        childId: String,
        category: CustomItemCategory,
        isSeeded: Bool = true
    ) async throws {
        let existing = try await count(childId: childId, category: category)
        guard existing == 0 else {
            logger.debug("Skipping seed for \(childId)/\(category.rawValue) — \(existing) item(s) already exist.")
            return
        }
        for name in names {
            let item = CustomItem(
                childId: childId,
                category: category,
                name: name,
                isSeeded: isSeeded
            )
            try await dittoManager.execute(
                query: QueryHelpers.upsert(into: AppConstants.Collections.customItems),
                arguments: ["document": item.toDittoDocument()]
            )
        }
        logger.info("Seeded \(names.count) item(s) for \(childId)/\(category.rawValue).")
    }
}
