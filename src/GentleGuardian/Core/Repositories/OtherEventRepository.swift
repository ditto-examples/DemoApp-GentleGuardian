import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for OtherEvent records.
@Observable
@MainActor
final class OtherEventRepository {

    // MARK: - Published State

    /// Other events for the currently observed child and date.
    private(set) var events: [OtherEvent] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "OtherEventRepository")
    @ObservationIgnored nonisolated(unsafe) private var eventsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        eventsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing other events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.otherEvents,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> OtherEvent in
                        let doc = item.value
                        let event = OtherEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe other events: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new other event using upsert semantics.
    ///
    /// - Parameter event: The other event to insert.
    func insert(event: OtherEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.otherEvents),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted other event: \(event.id)")
    }

    /// Updates an existing other event using upsert semantics.
    ///
    /// - Parameter event: The other event with updated fields.
    func update(event: OtherEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.otherEvents),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated other event: \(event.id)")
    }

    /// Soft-deletes an other event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.otherEvents),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted other event: \(eventId)")
    }

    // MARK: - One-Time Queries

    /// Returns distinct event names used by this child across all other events.
    ///
    /// Used to populate the "past names" picker in the logging form.
    ///
    /// - Parameter childId: The child's unique identifier.
    /// - Returns: An array of distinct event name strings, sorted alphabetically.
    func distinctNames(childId: String) async throws -> [String] {
        let query = """
            SELECT DISTINCT name
            FROM \(AppConstants.Collections.otherEvents)
            WHERE childId = :childId
            AND \(QueryHelpers.notArchived)
            ORDER BY name ASC
            """

        let result = try await dittoManager.execute(
            query: query,
            arguments: ["childId": childId]
        )

        return result.items.compactMap { item in
            let doc = item.value
            let name = doc["name"] as? String
            item.dematerialize()
            return name
        }.filter { !$0.isEmpty }
    }
}
