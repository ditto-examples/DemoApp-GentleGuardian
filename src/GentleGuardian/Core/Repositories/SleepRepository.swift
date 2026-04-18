import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for SleepEvent records.
@Observable
@MainActor
final class SleepRepository {

    // MARK: - Published State

    /// Sleep events for the currently observed child and date.
    private(set) var events: [SleepEvent] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "SleepRepository")
    @ObservationIgnored nonisolated(unsafe) private var eventsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        eventsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing sleep events for a child on a given day.
    ///
    /// - Parameters:
    ///   - childId: The child's unique identifier.
    ///   - date: The date string in "YYYY-MM-DD" format.
    func observeEvents(childId: String, date: String) {
        eventsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.sleep,
            additionalWhere: "date = :date"
        )

        Task {
            do {
                eventsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childDateArgs(childId, date: date)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> SleepEvent in
                        let doc = item.value
                        let event = SleepEvent(from: doc)
                        item.dematerialize()
                        return event
                    }
                    Task { @MainActor [weak self] in
                        self?.events = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe sleep events: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new sleep event using upsert semantics.
    ///
    /// - Parameter event: The sleep event to insert.
    func insert(event: SleepEvent) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.sleep),
            arguments: ["document": event.toDittoDocument()]
        )
        logger.debug("Inserted sleep event: \(event.id)")
    }

    /// Updates an existing sleep event using upsert semantics.
    ///
    /// - Parameter event: The sleep event with updated fields.
    func update(event: SleepEvent) async throws {
        var updated = event
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.sleep),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated sleep event: \(event.id)")
    }

    /// Soft-deletes a sleep event by setting isArchived = true.
    ///
    /// - Parameter eventId: The ID of the event to archive.
    func softDelete(eventId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.sleep),
            arguments: QueryHelpers.softDeleteArgs(eventId)
        )
        logger.debug("Soft-deleted sleep event: \(eventId)")
    }
}
