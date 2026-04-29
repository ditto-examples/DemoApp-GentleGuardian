import SwiftUI

/// Add/edit/swipe-delete UI for `CustomItem`s of a given child + category.
///
/// Reuses the `CustomItemRepository` already observing items for the parent
/// `CustomItemPickerView`, so the list stays in sync as edits land.
struct ManageCustomItemsView: View {

    // MARK: - Properties

    let childId: String
    let category: CustomItemCategory
    let repository: CustomItemRepository
    let attachmentLoader: CustomItemAttachmentLoader

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var showAddSheet: Bool = false
    @State private var deletionError: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()
            content
        }
        .navigationTitle(category == .formula ? "Manage Formulas" : "Manage Foods")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .trailingToolbar) {
                NavigationLink {
                    EditCustomItemView(
                        childId: childId,
                        category: category,
                        repository: repository,
                        attachmentLoader: attachmentLoader,
                        existing: nil
                    )
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if repository.items.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        List {
            ForEach(repository.items) { item in
                NavigationLink {
                    EditCustomItemView(
                        childId: childId,
                        category: category,
                        repository: repository,
                        attachmentLoader: attachmentLoader,
                        existing: item
                    )
                } label: {
                    row(item: item)
                }
                .listRowBackground(colors.surface)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await delete(item: item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if let deletionError {
                Text(deletionError)
                    .font(.ggBodySmall)
                    .foregroundStyle(colors.error)
                    .listRowBackground(colors.surface)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(colors.surface)
    }

    private func row(item: CustomItem) -> some View {
        HStack(spacing: GGSpacing.md) {
            thumbnail(token: item.attachmentToken)
            VStack(alignment: .leading, spacing: GGSpacing.xs) {
                Text(item.name)
                    .font(.ggBodyLarge)
                    .foregroundStyle(colors.onSurface)
                if item.isSeeded {
                    Text("Seeded")
                        .font(.ggLabelSmall)
                        .foregroundStyle(colors.onSurface.opacity(0.5))
                }
            }
            Spacer()
        }
        .padding(.vertical, GGSpacing.xs)
    }

    @ViewBuilder
    private func thumbnail(token: String?) -> some View {
        if let token, !token.isEmpty, let image = attachmentLoader.image(for: token) {
            Image(platformImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.onSurface.opacity(token == nil ? 0.05 : 0.08))
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
            Text("Tap + to add one.")
                .font(.ggBodySmall)
                .foregroundStyle(colors.onSurface.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, GGSpacing.xl)
    }

    // MARK: - Actions

    private func delete(item: CustomItem) async {
        do {
            try await repository.delete(item: item)
            if let token = item.attachmentToken, !token.isEmpty {
                attachmentLoader.evict(token: token)
            }
        } catch {
            deletionError = "Couldn't delete \(item.name). Please try again."
        }
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
