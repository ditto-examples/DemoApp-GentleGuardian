import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for DiaperEvent records.
@Observable
@MainActor
final class DiaperRepository {

    // MARK: - Published State

    /// Diaper events for the currently observed child and date.
    private(set) var events: [DiaperEvent] = []

    /// The most recent diaper event for the active child (used by home screen).
    private(set) var latestEvent: DiaperEvent?

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "DiaperRepository")
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

    /// Starts a live query observing diaper events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.diaper,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> DiaperEvent in
                        let doc = item.value
                        let event = DiaperEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe diaper events: \(error.localizedDescription)")
            }
        }
    }

    /// Starts a live query observing the most recent diaper event for a child.
    ///
    /// - Parameter childId: The child's unique identifier.
    func observeLatestDiaper(childId: String) {
        latestObserver?.cancel()

        let query = """
            SELECT * FROM \(AppConstants.Collections.diaper)
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
                    let event: DiaperEvent? = result.items.first.map { item in
                        let doc = item.value
                        let parsed = DiaperEvent(from: doc)
                        item.dematerialize()
                        return parsed
                    }
                    Task { @MainActor [weak self] in
                        self?.latestEvent = event
                    }
                }
            } catch {
                logger.error("Failed to observe latest diaper: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new diaper event using upsert semantics.
    ///
    /// - Parameter event: The diaper event to insert.
    func insert(event: DiaperEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.diaper),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted diaper event: \(event.id)")
    }

    /// Updates an existing diaper event using upsert semantics.
    ///
    /// - Parameter event: The diaper event with updated fields.
    func update(event: DiaperEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.diaper),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated diaper event: \(event.id)")
    }

    /// Soft-deletes a diaper event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.diaper),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted diaper event: \(eventId)")
    }

    // MARK: - One-Time Queries

    /// Returns the count of diaper events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    /// - Returns: The number of diaper events.
    func countForDay(childId: String, date: String) async throws -> Int {
        let result = try await dittoManager.execute(
            query: QueryHelpers.countForDate(from: AppConstants.Collections.diaper),
            arguments: QueryHelpers.childDateArgs(childId, date: date)
        )

        guard let item = result.items.first else { return 0 }
        let doc = item.value
        let count = doc["count"] as? Int ?? 0
        item.dematerialize()
        return count
    }
}
