import Testing
import Foundation
@testable import GentleGuardian

/// Tests for ActivityRepository query generation, argument passing, and observer lifecycle.
@Suite("ActivityRepository Tests")
struct ActivityRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        let event = ActivityEvent(
            id: "activity-1",
            childId: "child-1",
            activityType: .tummyTime,
            date: "2026-04-15",
            durationMinutes: 20,
            description: "On the play mat"
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
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.activity)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "activity-1")
        #expect(doc?["childId"] as? String == "child-1")
        #expect(doc?["activityType"] as? String == "tummyTime")
        #expect(doc?["durationMinutes"] as? Int == 20)
        #expect(doc?["description"] as? String == "On the play mat")
        #expect(doc?["date"] as? String == "2026-04-15")
    }

    @Test("insert bath event sends correct activity type")
    @MainActor
    func insertBathEvent() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        let event = ActivityEvent(
            id: "activity-bath",
            childId: "child-1",
            activityType: .bath,
            durationMinutes: 10
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        let doc = queries[0].arguments["document"] as? [String: Any?]
        #expect(doc?["activityType"] as? String == "bath")
        #expect(doc?["durationMinutes"] as? Int == 10)
    }

    // MARK: - Update

    @Test("update sends upsert query with updated document")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        let event = ActivityEvent(
            id: "activity-2",
            childId: "child-1",
            activityType: .outdoorPlay,
            durationMinutes: 45
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
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.activity)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "activity-2")
        #expect(doc?["activityType"] as? String == "outdoorPlay")
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "activity-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.activity)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "activity-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeEvents registers observer with childId and date filters")
    @MainActor
    func observeEventsRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        repo.observeEvents(childId: "child-1", date: "2026-04-15")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.activity)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("date = :date"))
        #expect(observer.query.contains(QueryHelpers.notArchived))
        #expect(observer.query.contains("ORDER BY timestamp DESC"))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["date"] as? String == "2026-04-15")
    }

    // MARK: - Total Duration Query

    @Test("totalDurationForDay uses correct SUM query and arguments")
    @MainActor
    func totalDurationForDayQuery() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)

        do {
            _ = try await repo.totalDurationForDay(
                childId: "child-1",
                date: "2026-04-15",
                activityType: .tummyTime
            )
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("SUM(durationMinutes)"))
        #expect(query.query.contains("totalMinutes"))
        #expect(query.query.contains("FROM \(AppConstants.Collections.activity)"))
        #expect(query.query.contains("childId = :childId"))
        #expect(query.query.contains("date = :date"))
        #expect(query.query.contains("activityType = :activityType"))
        #expect(query.query.contains(QueryHelpers.notArchived))

        #expect(query.arguments["childId"] as? String == "child-1")
        #expect(query.arguments["date"] as? String == "2026-04-15")
        #expect(query.arguments["activityType"] as? String == "tummyTime")
    }

    // MARK: - Error Handling

    @Test("softDelete propagates DittoManager errors")
    @MainActor
    func softDeletePropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = ActivityRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "activity-err")
            Issue.record("Expected error to be thrown")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
