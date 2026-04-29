import SwiftUI

/// Cross-day list of rated solid foods with happy / neutral / frown counts
/// and an All / Liked / Hated filter.
///
/// Mirrors the layout of `FoodReactionsView`'s rows but is owned by the
/// Summary tab so the segmented control can switch between sections without
/// pushing a separate screen.
struct FoodRankingList: View {

    @Binding var filter: FoodRankingFilter
    let summaries: [FoodReactionSummary]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: GGSpacing.md) {
            filterPicker

            if summaries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: GGSpacing.sm) {
                    ForEach(summaries) { summary in
                        row(summary: summary)
                    }
                }
                .accessibilityIdentifier("food-ranking-list")
            }
        }
    }

    // MARK: - Filter Picker

    @ViewBuilder
    private var filterPicker: some View {
        let picker = Picker("Filter", selection: $filter) {
            ForEach(FoodRankingFilter.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .labelsHidden()
        .accessibilityIdentifier("food-ranking-filter")

        #if os(macOS)
        HStack {
            Spacer()
            picker.pickerStyle(.menu).frame(maxWidth: 200)
        }
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            HStack {
                Spacer()
                picker.pickerStyle(.menu).frame(maxWidth: 200)
            }
        } else {
            picker.pickerStyle(.wheel).frame(height: 120)
        }
        #endif
    }

    // MARK: - Row

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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: GGSpacing.md) {
            Text("🍽️").font(.system(size: 40))

            Text(emptyTitle)
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurfaceVariant)

            Text(emptyMessage)
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.xxl)
    }

    private var emptyTitle: String {
        switch filter {
        case .all: "No rated foods yet"
        case .liked: "No liked foods"
        case .hated: "No hated foods"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .all: "Rate a food when you log a solid feeding to see it ranked here."
        case .liked: "Foods rated more 😀 than 🙁 will appear here."
        case .hated: "Foods rated more 🙁 than 😀 will appear here."
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Food Ranking List") {
    @Previewable @State var filter: FoodRankingFilter = .all
    let sample: [FoodReactionSummary] = [
        FoodReactionSummary(
            foodName: "Avocado",
            totalCount: 4,
            happyCount: 3,
            neutralCount: 1,
            frownCount: 0
        ),
        FoodReactionSummary(
            foodName: "Broccoli",
            totalCount: 3,
            happyCount: 0,
            neutralCount: 1,
            frownCount: 2
        )
    ]
    return ScrollView {
        FoodRankingList(filter: $filter, summaries: sample)
            .pageHorizontalPadding()
    }
    .background(GGColors.surface)
}
