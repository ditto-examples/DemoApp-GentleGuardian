import SwiftUI

/// Grid of activity bubbles for quick event logging from the home screen.
///
/// Displays 6 bubbles: Feeding, Diaper, Health, Activity, Sleep, and Reading Time.
/// Each bubble triggers a callback with the corresponding event category.
struct QuickLogGrid: View {

    let onCategoryTapped: (EventCategory) -> Void

    var body: some View {
        GGQuickLogGrid(bubbles: [
            .init("Feeding", icon: "spoon.serving", tintColor: GGColors.primary) {
                onCategoryTapped(.feeding)
            },
            .init("Diaper", icon: "humidity.fill", tintColor: GGColors.tertiary) {
                onCategoryTapped(.diaper)
            },
            .init("Health", icon: "heart.fill", tintColor: GGColors.error) {
                onCategoryTapped(.health)
            },
            .init("Activity", icon: "figure.play", tintColor: GGColors.secondary) {
                onCategoryTapped(.activity)
            },
            .init("Sleep", icon: "moon.fill", tintColor: GGColors.onSurfaceVariant) {
                onCategoryTapped(.sleep)
            },
            .init("Other", icon: "pencil.and.outline", tintColor: GGColors.tertiary) {
                onCategoryTapped(.other)
            },
        ])
        .accessibilityIdentifier("quick-log-grid")
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
