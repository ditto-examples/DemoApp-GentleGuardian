import Foundation

/// Common DQL query fragments and builder utilities.
///
/// Centralizes query construction to reduce string duplication and ensure
/// consistent filtering across all repositories.
enum QueryHelpers {

    // MARK: - Common Fragments

    /// DQL WHERE clause fragment to exclude archived (soft-deleted) documents.
    static let notArchived = "coalesce(isArchived, false) = false"

    // MARK: - Query Builders

    /// Builds a SELECT query for a collection, filtering by childId and excluding archived records.
    ///
    /// - Parameters:
    ///   - collection: The Ditto collection name.
    ///   - additionalWhere: Optional additional WHERE clause conditions (without leading AND).
    ///   - orderBy: Optional ORDER BY clause (without the ORDER BY keyword).
    /// - Returns: A DQL query string with `:childId` as a named parameter.
    static func selectForChild(
        from collection: String,
        additionalWhere: String? = nil,
        orderBy: String = "timestamp DESC"
    ) -> String {
        var query = "SELECT * FROM \(collection) WHERE childId = :childId AND \(notArchived)"
        if let additionalWhere {
            query += " AND \(additionalWhere)"
        }
        query += " ORDER BY \(orderBy)"
        return query
    }

    /// Builds a SELECT query for a single document by ID.
    ///
    /// - Parameter collection: The Ditto collection name.
    /// - Returns: A DQL query string with `:id` as a named parameter.
    static func selectById(from collection: String) -> String {
        "SELECT * FROM \(collection) WHERE _id = :id AND \(notArchived)"
    }

    /// Builds a SELECT query for documents within a date range.
    ///
    /// - Parameters:
    ///   - collection: The Ditto collection name.
    ///   - additionalWhere: Optional additional WHERE clause conditions.
    /// - Returns: A DQL query string expecting `:childId`, `:startDate`, and `:endDate` parameters.
    static func selectForDateRange(
        from collection: String,
        additionalWhere: String? = nil
    ) -> String {
        var query = """
            SELECT * FROM \(collection)
            WHERE childId = :childId
            AND \(notArchived)
            AND date >= :startDate
            AND date <= :endDate
            """
        if let additionalWhere {
            query += " AND \(additionalWhere)"
        }
        query += " ORDER BY timestamp DESC"
        return query
    }

    /// Builds a SELECT COUNT query for documents matching a child and date.
    ///
    /// - Parameter collection: The Ditto collection name.
    /// - Returns: A DQL query string expecting `:childId` and `:date` parameters.
    static func countForDate(from collection: String) -> String {
        """
        SELECT COUNT(*) as count FROM \(collection)
        WHERE childId = :childId
        AND \(notArchived)
        AND date = :date
        """
    }

    /// Builds an INSERT query with ON ID CONFLICT DO UPDATE for upsert behavior.
    ///
    /// - Parameter collection: The Ditto collection name.
    /// - Returns: A DQL query string expecting a `:document` parameter.
    static func upsert(into collection: String) -> String {
        """
        INSERT INTO \(collection)
        DOCUMENTS (:document)
        ON ID CONFLICT DO UPDATE
        """
    }

    /// Builds a soft-delete UPDATE query that sets isArchived = true.
    ///
    /// - Parameter collection: The Ditto collection name.
    /// - Returns: A DQL query string expecting an `:id` and `:updatedAt` parameter.
    static func softDelete(from collection: String) -> String {
        """
        UPDATE \(collection)
        SET isArchived = true, updatedAt = :updatedAt
        WHERE _id = :id
        """
    }

    /// Builds a query to find a child by sync code.
    ///
    /// - Returns: A DQL query string expecting a `:syncCode` parameter.
    static func findChildBySyncCode() -> String {
        """
        SELECT * FROM \(AppConstants.Collections.children)
        WHERE syncCode = :syncCode
        AND \(notArchived)
        """
    }

    /// Builds an EVICT query for a collection filtered by childId.
    ///
    /// - Parameter collection: The Ditto collection name.
    /// - Returns: A DQL query string expecting a `:childId` parameter.
    static func evictForChild(from collection: String) -> String {
        "EVICT FROM \(collection) WHERE childId = :childId"
    }

    // MARK: - Argument Builders

    /// Creates a standard arguments dictionary with childId.
    static func childArgs(_ childId: String) -> [String: Any] {
        ["childId": childId]
    }

    /// Creates arguments for a child + date query.
    static func childDateArgs(_ childId: String, date: String) -> [String: Any] {
        ["childId": childId, "date": date]
    }

    /// Creates arguments for a child + date range query.
    static func childDateRangeArgs(
        _ childId: String,
        startDate: String,
        endDate: String
    ) -> [String: Any] {
        ["childId": childId, "startDate": startDate, "endDate": endDate]
    }

    /// Creates arguments for an ID-based query.
    static func idArgs(_ id: String) -> [String: Any] {
        ["id": id]
    }

    /// Creates arguments for a soft-delete operation.
    static func softDeleteArgs(_ id: String) -> [String: Any] {
        ["id": id, "updatedAt": DateService.iso8601String(from: Date())]
    }
}
