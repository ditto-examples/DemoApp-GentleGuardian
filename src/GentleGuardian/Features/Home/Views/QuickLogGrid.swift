import SwiftUI

/// Grid of activity bubbles for quick event logging from the home screen.
///
/// Displays 6 bubbles: Feeding, Diaper, Health, Activity, Sleep, and Reading Time.
/// Each bubble triggers a callback with the corresponding event category.
struct QuickLogGrid: View {

    let onCategoryTapped: (EventCategory) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GGQuickLogGrid(bubbles: [
            .init("Feeding", icon: "spoon.serving", tintColor: colors.primary) {
                onCategoryTapped(.feeding)
            },
            .init("Diaper", icon: "humidity.fill", tintColor: colors.tertiary) {
                onCategoryTapped(.diaper)
            },
            .init("Health", icon: "heart.fill", tintColor: colors.error) {
                onCategoryTapped(.health)
            },
            .init("Activity", icon: "figure.play", tintColor: colors.secondary) {
                onCategoryTapped(.activity)
            },
            .init("Sleep", icon: "moon.fill", tintColor: colors.onSurfaceVariant) {
                onCategoryTapped(.sleep)
            },
            .init("Other", icon: "pencil.and.outline", tintColor: colors.tertiary) {
                onCategoryTapped(.other)
            },
        ])
        .accessibilityIdentifier("quick-log-grid")
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Quick Log Grid") {
    VStack(alignment: .leading, spacing: GGSpacing.md) {
        Text("Quick Log")
            .font(.ggTitleLarge)
            .foregroundStyle(GGColors.onSurface)
            .asymmetricHorizontalPadding()

        QuickLogGrid { category in
            print("Tapped: \(category.displayName)")
        }
        .pageHorizontalPadding()
    }
    .padding(.vertical, GGSpacing.lg)
    .background(GGColors.surface)
}
