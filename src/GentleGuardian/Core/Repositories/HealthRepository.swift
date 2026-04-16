import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for HealthEvent records.
@Observable
@MainActor
final class HealthRepository {

    // MARK: - Published State

    /// Health events for the currently observed child and date.
    private(set) var events: [HealthEvent] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "HealthRepository")
    @ObservationIgnored nonisolated(unsafe) private var eventsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        eventsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing health events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.health,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> HealthEvent in
                        let doc = item.value
                        let event = HealthEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe health events: \(error.localizedDescription)")
            }
        }
    }

    /// Starts a live query observing health events filtered by type for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    ///   - type: The health event type to filter by.
    func observeEventsByType(childId: String, date: String, type: HealthEventType) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.health,
            additionalWhere: "date = :date AND type = :type"
        )

        var args = QueryHelpers.childDateArgs(childId, date: date)
        args["type"] = type.rawValue
        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: args
                ) { [weak self] result in
                    let parsed = result.items.map { item -> HealthEvent in
                        let doc = item.value
                        let event = HealthEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe health events by type: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new health event using upsert semantics.
    ///
    /// - Parameter event: The health event to insert.
    func insert(event: HealthEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.health),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted health event: \(event.id)")
    }

    /// Updates an existing health event using upsert semantics.
    ///
    /// - Parameter event: The health event with updated fields.
    func update(event: HealthEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.health),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated health event: \(event.id)")
    }

    /// Soft-deletes a health event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.health),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted health event: \(eventId)")
    }

    // MARK: - One-Time Queries

    /// Returns the most recent growth event for a child.
    ///
    /// - Parameter childId: The child's unique identifier.
    /// - Returns: The latest growth event, or `nil` if none exist.
    func latestGrowth(childId: String) async throws -> HealthEvent? {
        let query = """
            SELECT * FROM \(AppConstants.Collections.health)
            WHERE childId = :childId
            AND type = :type
            AND \(QueryHelpers.notArchived)
            ORDER BY timestamp DESC
            LIMIT 1
            """

        var args = QueryHelpers.childArgs(childId)
        args["type"] = HealthEventType.growth.rawValue

        let result = try await dittoManager.execute(
            query: query,
            arguments: args
        )

        guard let item = result.items.first else { return nil }
        let doc = item.value
        let event = HealthEvent(from: doc)
        item.dematerialize()
        return event
    }
}
