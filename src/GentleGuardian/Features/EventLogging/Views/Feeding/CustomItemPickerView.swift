import SwiftUI

/// Searchable picker that lists `CustomItem`s for a given child + category.
/// Tapping a row writes the chosen item's name back via `onSelect` and pops.
///
/// A `Manage` toolbar button pushes `ManageCustomItemsView` for add/edit/delete.
struct CustomItemPickerView: View {

    // MARK: - Properties

    let childId: String
    let category: CustomItemCategory
    let attachmentLoader: CustomItemAttachmentLoader
    /// Called with the selected item's display name and attachment token (if any).
    let onSelect: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var repository: CustomItemRepository?
    @State private var searchText: String = ""
    /// Per-food reaction rollup keyed by lowercased food name. Populated on
    /// appear when `category == .solidFood`; stays empty otherwise.
    @State private var reactionsByFood: [String: FoodReactionSummary] = [:]
    /// All solid feedings for the active child, retained so the dedicated
    /// reactions screen can be pushed without re-fetching.
    @State private var allSolidFeedings: [FeedingEvent] = []

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            if let repository {
                content(repository: repository)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(category == .formula ? "Choose Formula" : "Choose Food")
        .inlineNavigationBarTitle()
        .toolbar {
            if category == .solidFood {
                ToolbarItem(placement: .trailingToolbar) {
                    NavigationLink {
                        FoodReactionsView(feedings: allSolidFeedings)
                    } label: {
                        Text("All reactions")
                            .foregroundStyle(colors.primary)
                    }
                }
            }
            ToolbarItem(placement: .trailingToolbar) {
                if let repository {
                    NavigationLink {
                        ManageCustomItemsView(
                            childId: childId,
                            category: category,
                            repository: repository,
                            attachmentLoader: attachmentLoader
                        )
                    } label: {
                        Text("Manage")
                            .foregroundStyle(colors.primary)
                    }
                }
            }
        }
        .onAppear {
            if repository == nil {
                let repo = CustomItemRepository(dittoManager: DittoManager.shared)
                repo.observeItems(childId: childId, category: category)
                repository = repo
            }
            if category == .solidFood {
                Task { await loadReactionSummaries() }
            }
        }
    }

    // MARK: - Reaction Loading

    private func loadReactionSummaries() async {
        let feedingRepo = FeedingRepository(dittoManager: DittoManager.shared)
        do {
            let events = try await feedingRepo.fetchAllSolidFeedings(childId: childId)
            let summaries = FoodReactionAggregator.summarize(events: events)
            allSolidFeedings = events
            reactionsByFood = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })
        } catch {
            // Non-fatal: leave badges empty if the fetch fails.
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(repository: CustomItemRepository) -> some View {
        let filtered = filteredItems(repository.items)
        ScrollView {
            VStack(spacing: GGSpacing.sm) {
                searchField

                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { item in
                        Button {
                            onSelect(item.name, item.attachmentToken)
                            dismiss()
                        } label: {
                            row(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    private var searchField: some View {
        GGTextField(
            "Search",
            text: $searchText,
            icon: "magnifyingglass"
        )
    }

    private func row(item: CustomItem) -> some View {
        GGCard(style: .standard) {
            HStack(spacing: GGSpacing.md) {
                thumbnail(token: item.attachmentToken)
                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                    Text(item.name)
                        .font(.ggBodyLarge)
                        .foregroundStyle(colors.onSurface)
                    if category == .solidFood,
                       let summary = reactionsByFood[item.name.lowercased()],
                       summary.totalRatedCount > 0 {
                        reactionBadge(summary: summary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.3))
            }
        }
    }

    /// Compact emoji + count badge showing how this food has been received.
    private func reactionBadge(summary: FoodReactionSummary) -> some View {
        HStack(spacing: GGSpacing.sm) {
            reactionCount(emoji: SolidReaction.happy.emoji, count: summary.happyCount)
            reactionCount(emoji: SolidReaction.neutral.emoji, count: summary.neutralCount)
            reactionCount(emoji: SolidReaction.frown.emoji, count: summary.frownCount)
            Text("· \(summary.totalCount) total")
                .font(.ggLabelSmall)
                .foregroundStyle(colors.onSurface.opacity(0.5))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.happyCount) liked, \(summary.neutralCount) so-so, \(summary.frownCount) disliked, \(summary.totalCount) total")
    }

    private func reactionCount(emoji: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Text(emoji).font(.system(size: 14))
            Text("\(count)")
                .font(.ggLabelSmall)
                .foregroundStyle(colors.onSurface.opacity(count == 0 ? 0.3 : 0.7))
        }
    }

    @ViewBuilder
    private func thumbnail(token: String?) -> some View {
        if let token, !token.isEmpty {
            if let image = attachmentLoader.image(for: token) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.onSurface.opacity(0.08))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: category == .formula ? "drop" : "fork.knife")
                            .foregroundStyle(colors.onSurface.opacity(0.4))
                    }
            }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.onSurface.opacity(0.05))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: category == .formula ? "drop" : "fork.knife")
                        .foregroundStyle(colors.onSurface.opacity(0.4))
                }
        }
    }

    private var emptyState: some View {
        VStack(spacing: GGSpacing.sm) {
            Image(systemName: category == .formula ? "drop.degreesign" : "fork.knife.circle")
                .font(.system(size: 40))
                .foregroundStyle(colors.onSurface.opacity(0.3))
            Text(category == .formula
                 ? "No formulas yet."
                 : "No foods yet.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            Text("Tap Manage to add one.")
                .font(.ggBodySmall)
                .foregroundStyle(colors.onSurface.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.xl)
    }

    // MARK: - Helpers

    private func filteredItems(_ items: [CustomItem]) -> [CustomItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
