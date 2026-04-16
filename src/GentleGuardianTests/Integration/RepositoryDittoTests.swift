import Testing
import Foundation
@testable import GentleGuardian

/// Integration tests for repository CRUD lifecycle using MockDittoManager.
///
/// These tests verify the full lifecycle of documents through repositories:
/// insert, query verification, update, re-query, soft-delete, and exclusion.
///
/// Since `MockDittoManager` cannot return real `QueryResult` objects, these tests
/// verify that the correct DQL queries and arguments are sent for each operation.
/// For tests against a real Ditto instance, XCTSkipIf guards are used.
@Suite("Repository Ditto Integration Tests")
struct RepositoryDittoTests {

    // MARK: - Full CRUD Lifecycle: FeedingRepository

    @Test("FeedingRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func feedingCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = FeedingRepository(dittoManager: mock)
        let childId = "crud-child"
        let eventId = "crud-feed-1"

        // 1. INSERT
        let event = FeedingEvent(
            id: eventId,
            childId: childId,
            type: .bottle,
            date: "2026-04-15",
            bottleQuantity: 150.0,
            bottleQuantityUnit: .ml,
            formulaType: "Similac"
        )

        do {
            try await repo.insert(event: event)
        } catch {
            // Expected: MockDittoError.cannotReturnQueryResult
        }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)
        #expect(queries[0].query.contains("INSERT INTO \(AppConstants.Collections.feeding)"))

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["_id"] as? String == eventId)
        #expect(insertDoc?["childId"] as? String == childId)
        #expect(insertDoc?["type"] as? String == "bottle")
        #expect(insertDoc?["bottleQuantity"] as? Double == 150.0)
        #expect(insertDoc?["formulaType"] as? String == "Similac")
        #expect(insertDoc?["isArchived"] as? Bool == false)

        // 2. Verify observer registration (simulates query to check existence)
        repo.observeEvents(childId: childId, date: "2026-04-15")
        try? await Task.sleep(for: .milliseconds(100))

        let observers = await mock.registeredObservers
        #expect(observers.count == 1)
        #expect(observers[0].query.contains("childId = :childId"))
        #expect(observers[0].arguments["childId"] as? String == childId)

        // 3. UPDATE
        var updatedEvent = event
        updatedEvent.bottleQuantity = 180.0

        do {
            try await repo.update(event: updatedEvent)
        } catch {
            // Expected
        }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["_id"] as? String == eventId)
        #expect(updateDoc?["bottleQuantity"] as? Double == 180.0)

        // 4. SOFT DELETE
        do {
            try await repo.softDelete(eventId: eventId)
        } catch {
            // Expected
        }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("UPDATE \(AppConstants.Collections.feeding)"))
        #expect(queries[2].query.contains("SET isArchived = true"))
        #expect(queries[2].arguments["id"] as? String == eventId)

        // 5. Verify soft-delete exclusion: observer query includes notArchived filter
        #expect(observers[0].query.contains(QueryHelpers.notArchived))
    }

    // MARK: - Full CRUD Lifecycle: ChildRepository

    @Test("ChildRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func childCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = ChildRepository(dittoManager: mock)
        let childId = "crud-child-1"

        // 1. INSERT
        let child = Child(
            id: childId,
            firstName: "Emma",
            birthday: Date(timeIntervalSince1970: 1_700_000_000),
            sex: .female,
            syncCode: "EMM001"
        )

        do {
            try await repo.insert(child: child)
        } catch { /* Expected */ }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)
        #expect(queries[0].query.contains("INSERT INTO \(AppConstants.Collections.children)"))

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["_id"] as? String == childId)
        #expect(insertDoc?["firstName"] as? String == "Emma")
        #expect(insertDoc?["syncCode"] as? String == "EMM001")

        // 2. UPDATE
        var updatedChild = child
        updatedChild.firstName = "Emma Rose"

        do {
            try await repo.update(child: updatedChild)
        } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["firstName"] as? String == "Emma Rose")

        // 3. SOFT DELETE
        do {
            try await repo.softDelete(childId: childId)
        } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("UPDATE \(AppConstants.Collections.children)"))
        #expect(queries[2].query.contains("SET isArchived = true"))
    }

    // MARK: - Full CRUD Lifecycle: DiaperRepository

    @Test("DiaperRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func diaperCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = DiaperRepository(dittoManager: mock)
        let eventId = "crud-diaper-1"

        // 1. INSERT
        let event = DiaperEvent(
            id: eventId,
            childId: "child-1",
            type: .poop,
            date: "2026-04-15",
            quantity: .big,
            color: .brown,
            consistency: .solid
        )

        do { try await repo.insert(event: event) } catch { /* Expected */ }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["type"] as? String == "poop")
        #expect(insertDoc?["quantity"] as? String == "big")
        #expect(insertDoc?["color"] as? String == "brown")
        #expect(insertDoc?["consistency"] as? String == "solid")

        // 2. UPDATE
        var updatedEvent = event
        updatedEvent.quantity = .medium

        do { try await repo.update(event: updatedEvent) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["quantity"] as? String == "medium")

        // 3. SOFT DELETE
        do { try await repo.softDelete(eventId: eventId) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("SET isArchived = true"))
    }

    // MARK: - Full CRUD Lifecycle: HealthRepository

    @Test("HealthRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func healthCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = HealthRepository(dittoManager: mock)
        let eventId = "crud-health-1"

        // 1. INSERT temperature event
        let event = HealthEvent(
            id: eventId,
            childId: "child-1",
            type: .temperature,
            date: "2026-04-15",
            temperatureValue: 98.6,
            temperatureUnit: .fahrenheit
        )

        do { try await repo.insert(event: event) } catch { /* Expected */ }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["type"] as? String == "temperature")
        #expect(insertDoc?["temperatureValue"] as? Double == 98.6)
        #expect(insertDoc?["temperatureUnit"] as? String == "fahrenheit")

        // 2. UPDATE
        var updatedEvent = event
        updatedEvent.temperatureValue = 99.2

        do { try await repo.update(event: updatedEvent) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["temperatureValue"] as? Double == 99.2)

        // 3. SOFT DELETE
        do { try await repo.softDelete(eventId: eventId) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("SET isArchived = true"))
    }

    // MARK: - Full CRUD Lifecycle: ActivityRepository

    @Test("ActivityRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func activityCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = ActivityRepository(dittoManager: mock)
        let eventId = "crud-activity-1"

        // 1. INSERT
        let event = ActivityEvent(
            id: eventId,
            childId: "child-1",
            activityType: .bath,
            date: "2026-04-15",
            durationMinutes: 20,
            description: "Evening bath"
        )

        do { try await repo.insert(event: event) } catch { /* Expected */ }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["activityType"] as? String == "bath")
        #expect(insertDoc?["durationMinutes"] as? Int == 20)
        #expect(insertDoc?["description"] as? String == "Evening bath")

        // 2. UPDATE
        var updatedEvent = event
        updatedEvent.durationMinutes = 30

        do { try await repo.update(event: updatedEvent) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["durationMinutes"] as? Int == 30)

        // 3. SOFT DELETE
        do { try await repo.softDelete(eventId: eventId) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("SET isArchived = true"))
    }

    // MARK: - Full CRUD Lifecycle: CustomItemRepository

    @Test("CustomItemRepository full CRUD lifecycle sends correct queries")
    @MainActor
    func customItemCRUDLifecycle() async {
        let mock = MockDittoManager()
        let repo = CustomItemRepository(dittoManager: mock)
        let itemId = "crud-custom-1"

        // 1. INSERT
        let item = CustomItem(
            id: itemId,
            childId: "child-1",
            category: .formula,
            name: "Similac Pro-Advance",
            defaultQuantity: 120.0,
            defaultQuantityUnit: "ml"
        )

        do { try await repo.insert(item: item) } catch { /* Expected */ }

        var queries = await mock.executedQueries
        #expect(queries.count == 1)

        let insertDoc = queries[0].arguments["document"] as? [String: Any?]
        #expect(insertDoc?["category"] as? String == "formula")
        #expect(insertDoc?["name"] as? String == "Similac Pro-Advance")
        #expect(insertDoc?["defaultQuantity"] as? Double == 120.0)

        // 2. UPDATE
        var updatedItem = item
        updatedItem.name = "Similac Advance Gold"

        do { try await repo.update(item: updatedItem) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 2)

        let updateDoc = queries[1].arguments["document"] as? [String: Any?]
        #expect(updateDoc?["name"] as? String == "Similac Advance Gold")

        // 3. SOFT DELETE
        do { try await repo.softDelete(itemId: itemId) } catch { /* Expected */ }

        queries = await mock.executedQueries
        #expect(queries.count == 3)
        #expect(queries[2].query.contains("SET isArchived = true"))
    }

    // MARK: - Observer Tests

    @Test("observer registration includes notArchived filter for all repositories")
    @MainActor
    func observersIncludeNotArchivedFilter() async throws {
        let mock = MockDittoManager()

        // Register observers across different repositories
        let feedingRepo = FeedingRepository(dittoManager: mock)
        feedingRepo.observeEvents(childId: "child-1", date: "2026-04-15")

        let diaperRepo = DiaperRepository(dittoManager: mock)
        diaperRepo.observeEvents(childId: "child-1", date: "2026-04-15")

        let healthRepo = HealthRepository(dittoManager: mock)
        healthRepo.observeEvents(childId: "child-1", date: "2026-04-15")

        let activityRepo = ActivityRepository(dittoManager: mock)
        activityRepo.observeEvents(childId: "child-1", date: "2026-04-15")

        let childRepo = ChildRepository(dittoManager: mock)
        childRepo.observeChildren()

        // Wait for all observer Tasks to execute
        try await Task.sleep(for: .milliseconds(200))

        let observers = await mock.registeredObservers
        #expect(observers.count == 5)

        // All observer queries should include the notArchived filter
        for observer in observers {
            #expect(
                observer.query.contains(QueryHelpers.notArchived),
                "Observer query should include notArchived filter: \(observer.query)"
            )
        }
    }

    @Test("multiple concurrent observers can be registered on different repositories")
    @MainActor
    func multipleConcurrentObservers() async throws {
        let mock = MockDittoManager()

        let feedingRepo = FeedingRepository(dittoManager: mock)
        let diaperRepo = DiaperRepository(dittoManager: mock)

        // Register observers concurrently
        feedingRepo.observeEvents(childId: "child-1", date: "2026-04-15")
        feedingRepo.observeLatestFeeding(childId: "child-1")
        diaperRepo.observeEvents(childId: "child-1", date: "2026-04-15")
        diaperRepo.observeLatestDiaper(childId: "child-1")

        try await Task.sleep(for: .milliseconds(200))

        let observers = await mock.registeredObservers
        // FeedingRepository registers eventsObserver + latestObserver (first is cancelled by second call on same observer handle)
        // But since observeEvents and observeLatestFeeding use different observer handles, both should register
        #expect(observers.count >= 2, "Multiple observers should be registered across repositories")

        // Verify different collection queries
        let feedingObservers = observers.filter { $0.query.contains(AppConstants.Collections.feeding) }
        let diaperObservers = observers.filter { $0.query.contains(AppConstants.Collections.diaper) }
        #expect(feedingObservers.count >= 1)
        #expect(diaperObservers.count >= 1)
    }

    // MARK: - Soft Delete Exclusion Verification

    @Test("all SELECT queries from QueryHelpers include notArchived filter")
    func queryHelpersExcludeArchived() {
        let selectForChild = QueryHelpers.selectForChild(from: "test_collection")
        #expect(selectForChild.contains(QueryHelpers.notArchived))

        let selectById = QueryHelpers.selectById(from: "test_collection")
        #expect(selectById.contains(QueryHelpers.notArchived))

        let selectForDateRange = QueryHelpers.selectForDateRange(from: "test_collection")
        #expect(selectForDateRange.contains(QueryHelpers.notArchived))

        let countForDate = QueryHelpers.countForDate(from: "test_collection")
        #expect(countForDate.contains(QueryHelpers.notArchived))

        let findBySyncCode = QueryHelpers.findChildBySyncCode()
        #expect(findBySyncCode.contains(QueryHelpers.notArchived))
    }

    @Test("soft delete query sets isArchived but does not use EVICT")
    func softDeleteDoesNotEvict() {
        for collection in AppConstants.Collections.all {
            let deleteQuery = QueryHelpers.softDelete(from: collection)
            #expect(deleteQuery.contains("isArchived = true"))
            #expect(!deleteQuery.contains("EVICT"))
            #expect(deleteQuery.contains("UPDATE \(collection)"))
        }
    }

    // MARK: - Error Propagation

    @Test("repository operations propagate DittoManager errors correctly")
    @MainActor
    func errorPropagation() async {
        let mock = MockDittoManager()
        await mock.setFailQueries(true)

        let feedingRepo = FeedingRepository(dittoManager: mock)
        let diaperRepo = DiaperRepository(dittoManager: mock)
        let healthRepo = HealthRepository(dittoManager: mock)
        let activityRepo = ActivityRepository(dittoManager: mock)

        // Feeding insert
        do {
            try await feedingRepo.insert(event: TestHelpers.makeTestFeedingEvent())
            Issue.record("Expected error")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Diaper insert
        do {
            try await diaperRepo.insert(event: TestHelpers.makeTestDiaperEvent())
            Issue.record("Expected error")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Health insert
        do {
            try await healthRepo.insert(event: TestHelpers.makeTestHealthEvent())
            Issue.record("Expected error")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Activity insert
        do {
            try await activityRepo.insert(event: TestHelpers.makeTestActivityEvent())
            Issue.record("Expected error")
        } catch let error as DittoManagerError {
            #expect(error.localizedDescription.contains("Mock error"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
