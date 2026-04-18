import Testing
import Foundation
@testable import GentleGuardian

/// Tests for DiaperRepository query generation, argument passing, and observer lifecycle.
@Suite("DiaperRepository Tests")
struct DiaperRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        let event = DiaperEvent(
            id: "diaper-1",
            childId: "child-1",
            type: .poop,
            date: "2026-04-15",
            quantity: .big,
            color: .brown,
            consistency: .loose
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.diaper)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "diaper-1")
        #expect(doc?["childId"] as? String == "child-1")
        #expect(doc?["type"] as? String == "poop")
        #expect(doc?["quantity"] as? String == "big")
        #expect(doc?["color"] as? String == "brown")
        #expect(doc?["consistency"] as? String == "loose")
        #expect(doc?["date"] as? String == "2026-04-15")
    }

    // MARK: - Update

    @Test("update sends upsert query with correct fields")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        let event = DiaperEvent(
            id: "diaper-2",
            childId: "child-1",
            type: .pee,
            quantity: .little,
            notes: "Quick change"
        )

        do {
            try await repo.update(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.diaper)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "diaper-2")
        #expect(doc?["type"] as? String == "pee")
        #expect(doc?["notes"] as? String == "Quick change")
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "diaper-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.diaper)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("updatedAt = :updatedAt"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "diaper-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeEvents registers observer with childId and date filters")
    @MainActor
    func observeEventsRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        repo.observeEvents(childId: "child-1", date: "2026-04-15")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.diaper)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("date = :date"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY timestamp DESC"))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["date"] as? String == "2026-04-15")
    }

    @Test("observeLatestDiaper registers observer with LIMIT 1")
    @MainActor
    func observeLatestRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        repo.observeLatestDiaper(childId: "child-1")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.diaper)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY timestamp DESC"))
        #expect(observer.query.contains("LIMIT 1"))

        #expect(observer.arguments["childId"] as? String == "child-1")
    }

    // MARK: - Count Query

    @Test("countForDay uses correct COUNT query and arguments")
    @MainActor
    func countForDayQuery() async {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)

        do {
            _ = try await repo.countForDay(childId: "child-1", date: "2026-04-15")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("SELECT COUNT(*) as count FROM \(AppConstants.Collections.diaper)"))
        #expect(query.query.contains("childId = :childId"))
        #expect(query.query.contains("date = :date"))
        #expect(query.query.contains(QueryHelpers.notArchived))

        #expect(query.arguments["childId"] as? String == "child-1")
        #expect(query.arguments["date"] as? String == "2026-04-15")
    }

    // MARK: - Error Handling

    @Test("insert propagates DittoManager errors")
    @MainActor
    func insertPropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = DiaperRepository(dittoManager: mock)

        let event = DiaperEvent(
            id: "diaper-err",
            childId: "child-1",
            type: .pee
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected error to be thrown")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
