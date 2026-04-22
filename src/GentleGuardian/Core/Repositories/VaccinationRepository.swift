import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for VaccinationRecord documents.
@Observable
@MainActor
final class VaccinationRepository {

    // MARK: - Published State

    /// Vaccination records for the currently observed child.
    private(set) var records: [VaccinationRecord] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "VaccinationRepository")
    @ObservationIgnored nonisolated(unsafe) private var recordsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        recordsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing vaccination records for a child.
    func observeRecords(childId: String) {
        recordsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.vaccinationRecords,
            orderBy: "dateAdministered DESC"
        )

        Task {
            do {
                recordsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childArgs(childId)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> VaccinationRecord in
                        let doc = item.value
                        let record = VaccinationRecord(from: doc)
                        item.dematerialize()
                        return record
                    }
                    Task { @MainActor [weak self] in
                        self?.records = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe vaccination records: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new vaccination record.
    func insert(record: VaccinationRecord) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.vaccinationRecords),
            arguments: ["document": record.toDittoDocument()]
        )
        logger.debug("Inserted vaccination record: \(record.id)")
    }

    /// Updates an existing vaccination record.
    func update(record: VaccinationRecord) async throws {
        var updated = record
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.vaccinationRecords),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated vaccination record: \(record.id)")
    }

    /// Soft-deletes a vaccination record.
    func softDelete(recordId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.vaccinationRecords),
            arguments: QueryHelpers.softDeleteArgs(recordId)
        )
        logger.debug("Soft-deleted vaccination record: \(recordId)")
    }
}
