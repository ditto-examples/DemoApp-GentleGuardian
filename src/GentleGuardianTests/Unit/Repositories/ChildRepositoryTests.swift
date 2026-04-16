import Testing
import Foundation
@testable import GentleGuardian

/// Tests for ChildRepository query generation, argument passing, and observer lifecycle.
@Suite("ChildRepository Tests")
struct ChildRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        let child = Child(
            id: "child-1",
            firstName: "Emma",
            birthday: Date(),
            sex: .female,
            syncCode: "ABC123"
        )

        do {
            try await repo.insert(child: child)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected: MockDittoError.cannotReturnQueryResult
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.children)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        // Verify document argument contains the child's data
        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "child-1")
        #expect(doc?["firstName"] as? String == "Emma")
        #expect(doc?["syncCode"] as? String == "ABC123")
        #expect(doc?["sex"] as? String == "female")
    }

    // MARK: - Update

    @Test("update sends upsert query with updated timestamp")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        let child = Child(
            id: "child-2",
            firstName: "Liam",
            birthday: Date(),
            sex: .male,
            syncCode: "XYZ789"
        )

        do {
            try await repo.update(child: child)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.children)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "child-2")
        #expect(doc?["firstName"] as? String == "Liam")
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        do {
            try await repo.softDelete(childId: "child-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.children)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "child-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeChildren registers observer with correct query")
    @MainActor
    func observeChildrenRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        repo.observeChildren()

        // Allow the Task inside observeChildren to execute
        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.children)"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY firstName ASC"))
    }

    @Test("observeChild registers observer with correct ID parameter")
    @MainActor
    func observeChildRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        repo.observeChild(id: "child-99")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("_id = :id"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.arguments["id"] as? String == "child-99")
    }

    // MARK: - Query Reads

    @Test("findBySyncCode uses correct query and arguments")
    @MainActor
    func findBySyncCodeQuery() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        // Will return nil because mock throws
        let result = await repo.findBySyncCode(syncCode: "ABC123")

        #expect(result == nil)

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("syncCode = :syncCode"))
        #expect(query.query.contains(QueryHelpers.notArchived))
        #expect(query.arguments["syncCode"] as? String == "ABC123")
    }

    @Test("allChildIds uses correct query")
    @MainActor
    func allChildIdsQuery() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)

        do {
            _ = try await repo.allChildIds()
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("SELECT * FROM \(AppConstants.Collections.children)"))
        #expect(query.query.contains(QueryHelpers.notArchived))
    }

    // MARK: - Error Handling

    @Test("insert propagates DittoManager errors")
    @MainActor
    func insertPropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = ChildRepository(dittoManager: mock)

        let child = Child(
            firstName: "Test",
            birthday: Date(),
            sex: .other,
            syncCode: "ERR001"
        )

        do {
            try await repo.insert(child: child)
            Issue.record("Expected error to be thrown")
        } catch let error as DittoManagerError {
            // Verify it propagated the mock error
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            // MockDittoError.cannotReturnQueryResult is also acceptable
            // when shouldFailQueries was set after the query was recorded
        }
    }
}

// MARK: - Mock Helper Extension

extension MockDittoManager {
    /// Convenience for setting shouldFailQueries from tests.
    func setFailQueries(_ value: Bool) {
        shouldFailQueries = value
    }
}
