import Testing
import Foundation
@testable import GentleGuardian

/// Tests for `FoodReactionAggregator`'s grouping and counting logic, used by
/// the Summary tab's Food Ranking section and the inline picker badges.
struct FoodReactionAggregatorTests {

    // MARK: - Empty Inputs

    @Test("Empty input produces no summaries")
    func emptyInput() {
        let summaries = FoodReactionAggregator.summarize(events: [])
        #expect(summaries.isEmpty)
    }

    @Test("Non-solid feedings are ignored")
    func nonSolidFeedingsIgnored() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .bottle, bottleQuantity: 4, bottleQuantityUnit: .oz),
            FeedingEvent(id: "f2", childId: "c", type: .breast, breastDurationMinutes: 10, breastSide: .left),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)
        #expect(summaries.isEmpty)
    }

    @Test("Solid feedings without solidType are skipped")
    func missingSolidTypeSkipped() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, solidType: nil, solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, solidType: "   ", solidReaction: .happy),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)
        #expect(summaries.isEmpty)
    }

    // MARK: - Grouping

    @Test("Foods are grouped case-insensitively by name")
    func groupingCaseInsensitive() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, solidType: "avocado", solidReaction: .happy),
            FeedingEvent(id: "f3", childId: "c", type: .solid, solidType: "AVOCADO", solidReaction: .frown),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)

        #expect(summaries.count == 1)
        let summary = summaries[0]
        #expect(summary.totalCount == 3)
        #expect(summary.happyCount == 2)
        #expect(summary.frownCount == 1)
    }

    @Test("Display name uses the most recent feeding's casing")
    func displayNameFromLatestEvent() {
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_100_000)

        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, timestamp: earlier,
                         solidType: "AVOCADO", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, timestamp: later,
                         solidType: "Avocado", solidReaction: .happy),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)

        #expect(summaries.count == 1)
        #expect(summaries[0].foodName == "Avocado")
    }

    @Test("Whitespace is trimmed from food names")
    func whitespaceTrimmed() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, solidType: "  Banana  ", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, solidType: "Banana", solidReaction: .neutral),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)

        #expect(summaries.count == 1)
        #expect(summaries[0].totalCount == 2)
    }

    // MARK: - Counts

    @Test("Each reaction type increments its respective count")
    func reactionCountsIncrement() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, solidType: "Carrot", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, solidType: "Carrot", solidReaction: .neutral),
            FeedingEvent(id: "f3", childId: "c", type: .solid, solidType: "Carrot", solidReaction: .frown),
            FeedingEvent(id: "f4", childId: "c", type: .solid, solidType: "Carrot", solidReaction: nil),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)

        #expect(summaries.count == 1)
        let s = summaries[0]
        #expect(s.totalCount == 4)
        #expect(s.happyCount == 1)
        #expect(s.neutralCount == 1)
        #expect(s.frownCount == 1)
        #expect(s.totalRatedCount == 3)
    }

    @Test("Multiple foods are summarized independently")
    func multipleFoodsSummarized() {
        let events: [FeedingEvent] = [
            FeedingEvent(id: "f1", childId: "c", type: .solid, solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "c", type: .solid, solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "f3", childId: "c", type: .solid, solidType: "Broccoli", solidReaction: .frown),
        ]
        let summaries = FoodReactionAggregator.summarize(events: events)

        #expect(summaries.count == 2)
        let avocado = summaries.first { $0.foodName == "Avocado" }
        let broccoli = summaries.first { $0.foodName == "Broccoli" }
        #expect(avocado?.happyCount == 2)
        #expect(broccoli?.frownCount == 1)
    }

    // MARK: - Score

    @Test("Score is +1 when only happy ratings")
    func scoreAllHappy() {
        let summary = FoodReactionSummary(
            foodName: "Avocado",
            totalCount: 2,
            happyCount: 2,
            neutralCount: 0,
            frownCount: 0
        )
        #expect(summary.score == 1.0)
    }

    @Test("Score is -1 when only frown ratings")
    func scoreAllFrown() {
        let summary = FoodReactionSummary(
            foodName: "Broccoli",
            totalCount: 2,
            happyCount: 0,
            neutralCount: 0,
            frownCount: 2
        )
        #expect(summary.score == -1.0)
    }

    @Test("Score is 0 when there are no ratings")
    func scoreNoRatings() {
        let summary = FoodReactionSummary(
            foodName: "Squash",
            totalCount: 1,
            happyCount: 0,
            neutralCount: 0,
            frownCount: 0
        )
        #expect(summary.score == 0)
        #expect(summary.totalRatedCount == 0)
    }

    @Test("Score reflects net tilt of happy minus frown")
    func scoreReflectsNetTilt() {
        let summary = FoodReactionSummary(
            foodName: "Banana",
            totalCount: 4,
            happyCount: 3,
            neutralCount: 0,
            frownCount: 1
        )
        #expect(summary.score == 0.5)
    }
}
