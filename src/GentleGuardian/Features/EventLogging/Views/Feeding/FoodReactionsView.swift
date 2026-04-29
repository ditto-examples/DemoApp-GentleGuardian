import SwiftUI

/// Dedicated review screen that lists every food the caregiver has rated,
/// sorted by score so the foods most disliked surface first. Lets caregivers
/// decide what to avoid before a grocery run.
///
/// Pushed from `CustomItemPickerView`'s "All reactions" toolbar button. The
/// upstream view fetches all solid feedings once and passes them in so this
/// view is a pure renderer.
struct FoodReactionsView: View {

    // MARK: - Sort Options

    enum SortMode: String, CaseIterable, Identifiable {
        case avoidFirst
        case lovedFirst
        case alphabetical

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .avoidFirst: "Avoid first"
            case .lovedFirst: "Loved first"
            case .alphabetical: "A–Z"
            }
        }
    }

    // MARK: - Properties

    let feedings: [FeedingEvent]

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var sortMode: SortMode = .avoidFirst

    // MARK: - Body

    var body: some View {
        let summaries = sorted(rated)
        ZStack {
            colors.surface.ignoresSafeArea()

            if summaries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: GGSpacing.md) {
                        sortPicker
                        ForEach(summaries) { summary in
                            row(summary: summary)
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
        }
        .navigationTitle("Food Reactions")
        .inlineNavigationBarTitle()
    }

    // MARK: - Subviews

    private var sortPicker: some View {
        Picker("Sort", selection: $sortMode) {
            ForEach(SortMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private func row(summary: FoodReactionSummary) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                HStack {
                    Text(summary.foodName)
                        .font(.ggTitleMedium)
                        .foregroundStyle(colors.onSurface)
                    Spacer()
                    Text("\(summary.totalCount) fed")
                        .font(.ggLabelSmall)
                        .foregroundStyle(colors.onSurface.opacity(0.6))
                }

                HStack(spacing: GGSpacing.lg) {
                    countCell(reaction: .happy, count: summary.happyCount)
                    countCell(reaction: .neutral, count: summary.neutralCount)
                    countCell(reaction: .frown, count: summary.frownCount)
                }
            }
        }
    }

    private func countCell(reaction: SolidReaction, count: Int) -> some View {
        HStack(spacing: GGSpacing.xs) {
            Text(reaction.emoji).font(.system(size: 22))
            Text("\(count)")
                .font(.ggTitleMedium)
                .foregroundStyle(count > 0 ? reaction.tintColor : colors.onSurface.opacity(0.3))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(reaction.displayName)")
    }

    private var emptyState: some View {
        VStack(spacing: GGSpacing.md) {
            Text("🍽️").font(.system(size: 48))
            Text("No rated foods yet")
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurface)
            Text("Rate a food when you log a solid to see it here.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(GGSpacing.pageInsets)
    }

    // MARK: - Helpers

    /// Foods that have been rated at least once.
    private var rated: [FoodReactionSummary] {
        FoodReactionAggregator.summarize(events: feedings)
            .filter { $0.totalRatedCount > 0 }
    }

    private func sorted(_ summaries: [FoodReactionSummary]) -> [FoodReactionSummary] {
        switch sortMode {
        case .avoidFirst:
            return summaries.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score < rhs.score }
                if lhs.frownCount != rhs.frownCount { return lhs.frownCount > rhs.frownCount }
                return lhs.foodName.localizedCaseInsensitiveCompare(rhs.foodName) == .orderedAscending
            }
        case .lovedFirst:
            return summaries.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.happyCount != rhs.happyCount { return lhs.happyCount > rhs.happyCount }
                return lhs.foodName.localizedCaseInsensitiveCompare(rhs.foodName) == .orderedAscending
            }
        case .alphabetical:
            return summaries.sorted { lhs, rhs in
                lhs.foodName.localizedCaseInsensitiveCompare(rhs.foodName) == .orderedAscending
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Food Reactions") {
    NavigationStack {
        FoodReactionsView(feedings: [])
    }
}
