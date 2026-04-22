import SwiftUI

/// Modal sheet router that receives an EventCategory and presents
/// the appropriate sub-form for logging an event.
struct LogEventSheet: View {

    // MARK: - Properties

    /// The event category to log. If nil, shows a category picker.
    let category: EventCategory?

    /// The child ID to associate events with.
    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var selectedCategory: EventCategory?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let category = category ?? selectedCategory {
                    destinationView(for: category)
                } else {
                    categoryPicker
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView {
            VStack(spacing: GGSpacing.md) {
                Text("Log Event")
                    .font(.ggHeadlineMedium)
                    .foregroundStyle(colors.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .asymmetricHorizontalPadding()
                    .padding(.top, GGSpacing.md)

                ForEach(EventCategory.allCases, id: \.self) { cat in
                    GGCard(style: .standard) {
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: GGSpacing.md) {
                                Image(systemName: cat.iconName)
                                    .font(.ggTitleLarge)
                                    .foregroundStyle(colors.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                                    Text(cat.displayName)
                                        .font(.ggTitleMedium)
                                        .foregroundStyle(colors.onSurface)

                                    Text(categoryDescription(cat))
                                        .font(.ggBodySmall)
                                        .foregroundStyle(colors.onSurface.opacity(0.6))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.ggBodyMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(GGSpacing.pageInsets)
        }
        .background(colors.surface)
        .navigationTitle("Log Event")
        .inlineNavigationBarTitle()
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for category: EventCategory) -> some View {
        switch category {
        case .feeding:
            LogBottleView(childId: childId)
        case .diaper:
            LogDiaperView(childId: childId)
        case .health:
            LogMedicineView(childId: childId)
        case .activity:
            LogActivityView(childId: childId)
        case .sleep:
            LogSleepView(childId: childId)
        case .other:
            LogOtherView(childId: childId)
        }
    }

    // MARK: - Helpers

    private func categoryDescription(_ category: EventCategory) -> String {
        switch category {
        case .feeding: "Bottle, breast, or solid food"
        case .diaper: "Poop or pee changes"
        case .health: "Medicine, temperature, or growth"
        case .activity: "Bath, tummy time, and more"
        case .sleep: "Naps and overnight sleep"
        case .other: "Track any custom activity"
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Log Event Sheet") {
    LogEventSheet(category: nil, childId: "test-child")
}
