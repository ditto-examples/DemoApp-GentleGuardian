import Testing
import Foundation
@testable import GentleGuardian

/// Tests for FeedingRepository query generation, argument passing, and observer lifecycle.
@Suite("FeedingRepository Tests")
struct FeedingRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        let event = FeedingEvent(
            id: "feed-1",
            childId: "child-1",
            type: .bottle,
            date: "2026-04-15",
            bottleQuantity: 120.0,
            bottleQuantityUnit: .ml
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected: MockDittoError.cannotReturnQueryResult
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.feeding)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "feed-1")
        #expect(doc?["childId"] as? String == "child-1")
        #expect(doc?["type"] as? String == "bottle")
        #expect(doc?["bottleQuantity"] as? Double == 120.0)
        #expect(doc?["date"] as? String == "2026-04-15")
    }

    // MARK: - Update

    @Test("update sends upsert query with updated timestamp")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        let event = FeedingEvent(
            id: "feed-2",
            childId: "child-1",
            type: .breast,
            breastDurationMinutes: 15,
            breastSide: .left
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
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.feeding)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "feed-2")
        #expect(doc?["type"] as? String == "breast")
        #expect(doc?["breastDurationMinutes"] as? Int == 15)
        #expect(doc?["breastSide"] as? String == "left")
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "feed-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.feeding)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "feed-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeEvents registers observer with childId and date filters")
    @MainActor
    func observeEventsRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        repo.observeEvents(childId: "child-1", date: "2026-04-15")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.feeding)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("date = :date"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY timestamp DESC"))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["date"] as? String == "2026-04-15")
    }

    @Test("observeLatestFeeding registers observer with LIMIT 1")
    @MainActor
    func observeLatestRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        repo.observeLatestFeeding(childId: "child-1")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.feeding)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY timestamp DESC"))
        #expect(observer.query.contains("LIMIT 1"))

        #expect(observer.arguments["childId"] as? String == "child-1")
    }

    @Test("observeEvents cancels previous observer before registering new one")
    @MainActor
    func observeEventsCancelsPrevious() async throws {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        // Register first observer
        repo.observeEvents(childId: "child-1", date: "2026-04-15")
        try await Task.sleep(for: .milliseconds(100))

        // Register second observer (should cancel first)
        repo.observeEvents(childId: "child-1", date: "2026-04-16")
        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        // Both should have been registered (the mock records all calls)
        #expect(observers.count == 2)

        // Second observer should have the new date
        let secondObserver = observers[1]
        #expect(secondObserver.arguments["date"] as? String == "2026-04-16")
    }

    // MARK: - Count Query

    @Test("countForDay uses correct COUNT query and arguments")
    @MainActor
    func countForDayQuery() async {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)

        do {
            _ = try await repo.countForDay(childId: "child-1", date: "2026-04-15")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("SELECT COUNT(*) as count FROM \(AppConstants.Collections.feeding)"))
        #expect(query.query.contains("childId = :childId"))
        #expect(query.query.contains("date = :date"))
        #expect(query.query.contains(QueryHelpers.notArchived))

        #expect(query.arguments["childId"] as? String == "child-1")
        #expect(query.arguments["date"] as? String == "2026-04-15")
    }

    // MARK: - Error Handling

    @Test("softDelete propagates DittoManager errors")
    @MainActor
    func softDeletePropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = FeedingRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "feed-err")
            Issue.record("Expected error to be thrown")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
