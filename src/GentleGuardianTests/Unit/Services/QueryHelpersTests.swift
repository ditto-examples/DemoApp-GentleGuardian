import Testing
import Foundation
@testable import GentleGuardian

/// Tests for QueryHelpers DQL query builder utilities.
@Suite("QueryHelpers Tests")
struct QueryHelpersTests {

    @Test("notArchived fragment is correct")
    func notArchivedFragment() {
        #expect(QueryHelpers.notArchived == "coalesce(isArchived, false) = false")
    }

    @Test("selectForChild builds correct query")
    func selectForChild() {
        let query = QueryHelpers.selectForChild(from: "feeding")
        #expect(query.contains("SELECT * FROM feeding"))
        #expect(query.contains("childId = :childId"))
        #expect(query.contains(QueryHelpers.notArchived))
        #expect(query.contains("ORDER BY timestamp DESC"))
    }

    @Test("selectForChild with additional WHERE clause")
    func selectForChildWithWhere() {
        let query = QueryHelpers.selectForChild(
            from: "feeding",
            additionalWhere: "type = :type"
        )
        #expect(query.contains("AND type = :type"))
    }

    @Test("selectById builds correct query")
    func selectById() {
        let query = QueryHelpers.selectById(from: "children")
        #expect(query.contains("_id = :id"))
        #expect(query.contains(QueryHelpers.notArchived))
    }

    @Test("selectForDateRange builds correct query")
    func selectForDateRange() {
        let query = QueryHelpers.selectForDateRange(from: "diaper")
        #expect(query.contains("date >= :startDate"))
        #expect(query.contains("date <= :endDate"))
        #expect(query.contains("childId = :childId"))
    }

    @Test("upsert builds correct query")
    func upsert() {
        let query = QueryHelpers.upsert(into: "feeding")
        #expect(query.contains("INSERT INTO feeding"))
        #expect(query.contains("DOCUMENTS (:document)"))
        #expect(query.contains("ON ID CONFLICT DO UPDATE"))
    }

    @Test("softDelete builds correct query")
    func softDelete() {
        let query = QueryHelpers.softDelete(from: "health")
        #expect(query.contains("UPDATE health"))
        #expect(query.contains("SET isArchived = true"))
        #expect(query.contains("WHERE _id = :id"))
    }

    @Test("childArgs creates correct dictionary")
    func childArgs() {
        let args = QueryHelpers.childArgs("child-1")
        #expect(args["childId"] as? String == "child-1")
    }

    @Test("childDateArgs creates correct dictionary")
    func childDateArgs() {
        let args = QueryHelpers.childDateArgs("child-1", date: "2026-04-15")
        #expect(args["childId"] as? String == "child-1")
        #expect(args["date"] as? String == "2026-04-15")
    }

    @Test("softDeleteArgs creates correct dictionary")
    func softDeleteArgs() {
        let args = QueryHelpers.softDeleteArgs("doc-1")
        #expect(args["id"] as? String == "doc-1")
        #expect(args["updatedAt"] is String)
    }
}
