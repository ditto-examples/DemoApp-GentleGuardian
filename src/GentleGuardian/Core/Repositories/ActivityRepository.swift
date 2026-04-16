import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for ActivityEvent records.
@Observable
@MainActor
final class ActivityRepository {

    // MARK: - Published State

    /// Activity events for the currently observed child and date.
    private(set) var events: [ActivityEvent] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "ActivityRepository")
    @ObservationIgnored nonisolated(unsafe) private var eventsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        eventsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing activity events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.activity,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> ActivityEvent in
                        let doc = item.value
                        let event = ActivityEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe activity events: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new activity event using upsert semantics.
    ///
    /// - Parameter event: The activity event to insert.
    func insert(event: ActivityEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.activity),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted activity event: \(event.id)")
    }

    /// Updates an existing activity event using upsert semantics.
    ///
    /// - Parameter event: The activity event with updated fields.
    func update(event: ActivityEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.activity),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated activity event: \(event.id)")
    }

    /// Soft-deletes an activity event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.activity),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted activity event: \(eventId)")
    }

    // MARK: - One-Time Queries

    /// Returns the total duration in minutes for a specific activity type on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    ///   - activityType: The type of activity to sum durations for.
    /// - Returns: The total duration in minutes.
    func totalDurationForDay(childId: String, date: String, activityType: ActivityType) async throws -> Int {
        let query = """
            SELECT coalesce(SUM(durationMinutes), 0) as totalMinutes
            FROM \(AppConstants.Collections.activity)
            WHERE childId = :childId
            AND date = :date
            AND activityType = :activityType
            AND \(QueryHelpers.notArchived)
            """

        var args = QueryHelpers.childDateArgs(childId, date: date)
        args["activityType"] = activityType.rawValue

        let result = try await dittoManager.execute(
            query: query,
            arguments: args
        )

        guard let item = result.items.first else { return 0 }
        let doc = item.value
        let total = doc["totalMinutes"] as? Int ?? 0
        item.dematerialize()
        return total
    }
}
