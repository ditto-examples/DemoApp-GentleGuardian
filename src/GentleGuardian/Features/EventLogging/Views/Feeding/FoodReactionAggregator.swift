import Foundation

/// Per-food rollup of reactions across one or more solid feedings.
///
/// Used by both the inline picker badges in `CustomItemPickerView` and the
/// dedicated `FoodReactionsView` review screen so the rating math lives in a
/// single place.
struct FoodReactionSummary: Identifiable, Equatable, Sendable {

    /// Display name of the food (preserves casing from the most recent feed).
    let foodName: String

    /// Total times this food was fed (rated or not).
    let totalCount: Int

    /// Number of feedings rated `.happy`.
    let happyCount: Int

    /// Number of feedings rated `.neutral`.
    let neutralCount: Int

    /// Number of feedings rated `.frown`.
    let frownCount: Int

    /// Stable identifier — case-insensitive trimmed key shared with grouping.
    var id: String { foodName.lowercased() }

    /// Number of feedings that have any rating.
    var totalRatedCount: Int {
        happyCount + neutralCount + frownCount
    }

    /// Score in [-1, 1]: +1 means every rating was happy, -1 every rating was
    /// frown. Used to sort foods so the worst float to the top by default.
    /// Returns 0 when there are no ratings (caller should filter those out).
    var score: Double {
        let rated = totalRatedCount
        guard rated > 0 else { return 0 }
        return Double(happyCount - frownCount) / Double(rated)
    }
}

/// Pure helper that groups solid feedings by food name and counts reactions.
enum FoodReactionAggregator {

    /// Summarize the supplied feedings, one entry per unique food.
    /// - Filters to `.solid` events only.
    /// - Groups case-insensitively by `solidType` (after trimming whitespace).
    /// - Skips events with no `solidType` set.
    /// - Display name is taken from the most recent feeding so it reflects
    ///   any later casing fixes the caregiver made.
    static func summarize(events: [FeedingEvent]) -> [FoodReactionSummary] {
        var buckets: [String: Bucket] = [:]

        for event in events where event.type == .solid {
            guard let raw = event.solidType?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else { continue }

            let key = raw.lowercased()
            var bucket = buckets[key] ?? Bucket(displayName: raw, latestTimestamp: event.timestamp)

            if event.timestamp >= bucket.latestTimestamp {
                bucket.displayName = raw
                bucket.latestTimestamp = event.timestamp
            }

            bucket.totalCount += 1
            switch event.solidReaction {
            case .happy: bucket.happyCount += 1
            case .neutral: bucket.neutralCount += 1
            case .frown: bucket.frownCount += 1
            case .none: break
            }

            buckets[key] = bucket
        }

        return buckets.values.map { bucket in
            FoodReactionSummary(
                foodName: bucket.displayName,
                totalCount: bucket.totalCount,
                happyCount: bucket.happyCount,
                neutralCount: bucket.neutralCount,
                frownCount: bucket.frownCount
            )
        }
    }

    private struct Bucket {
        var displayName: String
        var latestTimestamp: Date
        var totalCount: Int = 0
        var happyCount: Int = 0
        var neutralCount: Int = 0
        var frownCount: Int = 0
    }
}
