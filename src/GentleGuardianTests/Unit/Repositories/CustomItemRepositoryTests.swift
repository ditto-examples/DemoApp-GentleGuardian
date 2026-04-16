import Testing
import Foundation
@testable import GentleGuardian

/// Tests for CustomItemRepository query generation, argument passing, and observer lifecycle.
@Suite("CustomItemRepository Tests")
struct CustomItemRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        let item = CustomItem(
            id: "custom-1",
            childId: "child-1",
            category: .formula,
            name: "Similac Pro-Advance",
            defaultQuantity: 120.0,
            defaultQuantityUnit: "ml"
        )

        do {
            try await repo.insert(item: item)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.customItems)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "custom-1")
        #expect(doc?["childId"] as? String == "child-1")
        #expect(doc?["category"] as? String == "formula")
        #expect(doc?["name"] as? String == "Similac Pro-Advance")
        #expect(doc?["defaultQuantity"] as? Double == 120.0)
        #expect(doc?["defaultQuantityUnit"] as? String == "ml")
    }

    @Test("insert medicine custom item sends correct category")
    @MainActor
    func insertMedicineCustomItem() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        let item = CustomItem(
            id: "custom-med-1",
            childId: "child-1",
            category: .medicine,
            name: "Tylenol Infant"
        )

        do {
            try await repo.insert(item: item)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        let doc = queries[0].arguments["document"] as? [String: Any?]
        #expect(doc?["category"] as? String == "medicine")
        #expect(doc?["name"] as? String == "Tylenol Infant")
    }

    @Test("insert solidFood custom item sends correct category")
    @MainActor
    func insertSolidFoodCustomItem() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        let item = CustomItem(
            id: "custom-food-1",
            childId: "child-1",
            category: .solidFood,
            name: "Banana Puree"
        )

        do {
            try await repo.insert(item: item)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        let doc = queries[0].arguments["document"] as? [String: Any?]
        #expect(doc?["category"] as? String == "solidFood")
    }

    // MARK: - Update

    @Test("update sends upsert query with correct document")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        let item = CustomItem(
            id: "custom-2",
            childId: "child-1",
            category: .formula,
            name: "Updated Formula Brand"
        )

        do {
            try await repo.update(item: item)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.customItems)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "custom-2")
        #expect(doc?["name"] as? String == "Updated Formula Brand")
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        do {
            try await repo.softDelete(itemId: "custom-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.customItems)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("updatedAt = :updatedAt"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "custom-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeItems registers observer with childId and category filters")
    @MainActor
    func observeItemsRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        repo.observeItems(childId: "child-1", category: .formula)

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.customItems)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("category = :category"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY name ASC"))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["category"] as? String == "formula")
    }

    @Test("observeItems with medicine category passes correct argument")
    @MainActor
    func observeItemsMedicineCategory() async throws {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        repo.observeItems(childId: "child-1", category: .medicine)

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)
        #expect(observers[0].arguments["category"] as? String == "medicine")
    }

    @Test("observeItems with solidFood category passes correct argument")
    @MainActor
    func observeItemsSolidFoodCategory() async throws {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)

        repo.observeItems(childId: "child-1", category: .solidFood)

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)
        #expect(observers[0].arguments["category"] as? String == "solidFood")
    }

    // MARK: - Error Handling

    @Test("insert propagates DittoManager errors")
    @MainActor
    func insertPropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = CustomItemRepository(dittoManager: mock)

        let item = CustomItem(
            id: "custom-err",
            childId: "child-1",
            category: .formula,
            name: "Error Item"
        )

        do {
            try await repo.insert(item: item)
            Issue.record("Expected error to be thrown")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
