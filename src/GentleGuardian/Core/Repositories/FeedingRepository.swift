import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for FeedingEvent records.
@Observable
@MainActor
final class FeedingRepository {

    // MARK: - Published State

    /// Feeding events for the currently observed child and date.
    private(set) var events: [FeedingEvent] = []

    /// The most recent feeding event for the active child (used by home screen).
    private(set) var latestEvent: FeedingEvent?

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "FeedingRepository")
    @ObservationIgnored nonisolated(unsafe) private var eventsObserver: DittoStoreObserver?
    @ObservationIgnored nonisolated(unsafe) private var latestObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        eventsObserver?.cancel()
        latestObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing feeding events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.feeding,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> FeedingEvent in
                        let doc = item.value
                        let event = FeedingEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe feeding events: \(error.localizedDescription)")
            }
        }
    }

    /// Starts a live query observing the most recent feeding event for a child.
    ///
    /// - Parameter childId: The child's unique identifier.
    func observeLatestFeeding(childId: String) {
        latestObserver?.cancel()

        let query = """
            SELECT * FROM \(AppConstants.Collections.feeding)
            WHERE childId = :childId
            AND \(QueryHelpers.notArchived)
            ORDER BY timestamp DESC
            LIMIT 1
            """

        Task {
            do {
                latestObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childArgs(childId)
                ) { [weak self] result in
                    let event: FeedingEvent? = result.items.first.map { item in
                        let doc = item.value
                        let parsed = FeedingEvent(from: doc)
                        item.dematerialize()
                        return parsed
                    }
                    Task { @MainActor [weak self] in
                        self?.latestEvent = event
                    }
                }
            } catch {
                logger.error("Failed to observe latest feeding: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new feeding event using upsert semantics.
    ///
    /// - Parameter event: The feeding event to insert.
    func insert(event: FeedingEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.feeding),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted feeding event: \(event.id)")
    }

    /// Updates an existing feeding event using upsert semantics.
    ///
    /// - Parameter event: The feeding event with updated fields.
    func update(event: FeedingEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.feeding),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated feeding event: \(event.id)")
    }

    /// Soft-deletes a feeding event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.feeding),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted feeding event: \(eventId)")
    }

    // MARK: - One-Time Queries

    /// Returns the count of feeding events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    /// - Returns: The number of feeding events.
    func countForDay(childId: String, date: String) async throws -> Int {
        let result = try await dittoManager.execute(
            query: QueryHelpers.countForDate(from: AppConstants.Collections.feeding),
            arguments: QueryHelpers.childDateArgs(childId, date: date)
        )

        guard let item = result.items.first else { return 0 }
        let doc = item.value
        let count = doc["count"] as? Int ?? 0
        item.dematerialize()
        return count
    }
}
