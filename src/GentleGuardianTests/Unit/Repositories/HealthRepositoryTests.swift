import Testing
import Foundation
@testable import GentleGuardian

/// Tests for HealthRepository query generation, argument passing, and observer lifecycle.
@Suite("HealthRepository Tests")
struct HealthRepositoryTests {

    // MARK: - Insert

    @Test("insert sends upsert query with correct document")
    @MainActor
    func insertSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        let event = HealthEvent(
            id: "health-1",
            childId: "child-1",
            type: .medicine,
            date: "2026-04-15",
            medicineName: "Tylenol",
            medicineQuantity: 2.5,
            medicineQuantityUnit: .ml
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
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.health)"))
        #expect(query.query.contains("DOCUMENTS (:document)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))

        let doc = query.arguments["document"] as? [String: Any?]
        #expect(doc?["_id"] as? String == "health-1")
        #expect(doc?["childId"] as? String == "child-1")
        #expect(doc?["type"] as? String == "medicine")
        #expect(doc?["medicineName"] as? String == "Tylenol")
        #expect(doc?["medicineQuantity"] as? Double == 2.5)
    }

    @Test("insert temperature event sends correct fields")
    @MainActor
    func insertTemperatureEvent() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        let event = HealthEvent(
            id: "health-temp-1",
            childId: "child-1",
            type: .temperature,
            temperatureValue: 37.5,
            temperatureUnit: .celsius
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        let doc = queries[0].arguments["document"] as? [String: Any?]
        #expect(doc?["type"] as? String == "temperature")
        #expect(doc?["temperatureValue"] as? Double == 37.5)
        #expect(doc?["temperatureUnit"] as? String == "celsius")
    }

    @Test("insert growth event sends correct fields")
    @MainActor
    func insertGrowthEvent() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        let event = HealthEvent(
            id: "health-growth-1",
            childId: "child-1",
            type: .growth,
            heightValue: 60.5,
            heightUnit: .cm,
            weightValue: 5.2,
            weightUnit: .kg
        )

        do {
            try await repo.insert(event: event)
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        let doc = queries[0].arguments["document"] as? [String: Any?]
        #expect(doc?["type"] as? String == "growth")
        #expect(doc?["heightValue"] as? Double == 60.5)
        #expect(doc?["heightUnit"] as? String == "cm")
        #expect(doc?["weightValue"] as? Double == 5.2)
        #expect(doc?["weightUnit"] as? String == "kg")
    }

    // MARK: - Update

    @Test("update sends upsert query")
    @MainActor
    func updateSendsUpsert() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        let event = HealthEvent(
            id: "health-2",
            childId: "child-1",
            type: .medicine,
            medicineName: "Advil"
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
        #expect(query.query.contains("INSERT INTO \(AppConstants.Collections.health)"))
        #expect(query.query.contains("ON ID CONFLICT DO UPDATE"))
    }

    // MARK: - Soft Delete

    @Test("softDelete sends UPDATE with isArchived, not EVICT")
    @MainActor
    func softDeleteSendsUpdate() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        do {
            try await repo.softDelete(eventId: "health-to-delete")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("UPDATE \(AppConstants.Collections.health)"))
        #expect(query.query.contains("SET isArchived = true"))
        #expect(query.query.contains("WHERE _id = :id"))
        #expect(!query.query.contains("EVICT"))

        #expect(query.arguments["id"] as? String == "health-to-delete")
        #expect(query.arguments["updatedAt"] is String)
    }

    // MARK: - Observer Registration

    @Test("observeEvents registers observer with childId and date filters")
    @MainActor
    func observeEventsRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        repo.observeEvents(childId: "child-1", date: "2026-04-15")

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.health)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("date = :date"))
        #expect(observer.query.contains(QueryHelpers.notArchived))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["date"] as? String == "2026-04-15")
    }

    @Test("observeEventsByType registers observer with type filter")
    @MainActor
    func observeEventsByTypeRegistersObserver() async throws {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        repo.observeEventsByType(childId: "child-1", date: "2026-04-15", type: .temperature)

        try await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)

        let observer = observers[0]
        #expect(observer.query.contains("SELECT * FROM \(AppConstants.Collections.health)"))
        #expect(observer.query.contains("childId = :childId"))
        #expect(observer.query.contains("date = :date"))
        #expect(observer.query.contains("type = :type"))
        #expect(observer.query.contains(QueryHelpers.notArchived))

        #expect(observer.arguments["childId"] as? String == "child-1")
        #expect(observer.arguments["date"] as? String == "2026-04-15")
        #expect(observer.arguments["type"] as? String == "temperature")
    }

    // MARK: - Latest Growth Query

    @Test("latestGrowth uses correct query with type and LIMIT 1")
    @MainActor
    func latestGrowthQuery() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)

        do {
            _ = try await repo.latestGrowth(childId: "child-1")
            Issue.record("Expected throw from MockDittoManager")
        } catch {
            // Expected
        }

        let queries = await mock.executedQueries
        #expect(queries.count == 1)

        let query = queries[0]
        #expect(query.query.contains("SELECT * FROM \(AppConstants.Collections.health)"))
        #expect(query.query.contains("childId = :childId"))
        #expect(query.query.contains("type = :type"))
        #expect(query.query.contains(QueryHelpers.notArchived))
        #expect(query.query.contains("ORDER BY timestamp DESC"))
        #expect(query.query.contains("LIMIT 1"))

        #expect(query.arguments["childId"] as? String == "child-1")
        #expect(query.arguments["type"] as? String == "growth")
    }

    // MARK: - Error Handling

    @Test("insert propagates DittoManager errors")
    @MainActor
    func insertPropagatesErrors() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)
        let repo = HealthRepository(dittoManager: mock)

        let event = HealthEvent(
            id: "health-err",
            childId: "child-1",
            type: .medicine
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
