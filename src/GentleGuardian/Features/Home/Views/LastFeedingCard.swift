import SwiftUI

/// Hero card displaying the most recent feeding event.
///
/// Uses GGCard with .hero style for the gradient background.
/// Shows feeding type, time, relative time, and quantity/details.
struct LastFeedingCard: View {

    let typeLabel: String
    let timeString: String
    let relativeTime: String
    let detail: String
    let hasData: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GGCard(style: .hero) {
            if hasData {
                feedingContent
            } else {
                emptyContent
            }
        }
        .accessibilityIdentifier("last-feeding-card")
    }

    // MARK: - Content

    private var feedingContent: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text("MOST RECENT FEEDING")
                .font(.ggLabelSmall)
                .foregroundStyle(textColor.opacity(0.7))
                .tracking(1.2)

            Text("Last Feeding")
                .font(.ggTitleLarge)
                .foregroundStyle(textColor)

            HStack(alignment: .firstTextBaseline, spacing: GGSpacing.xs) {
                Text(typeLabel)
                    .font(GGTypography.bodyLarge(weight: .semibold))
                    .foregroundStyle(textColor)

                Text("  \(timeString)")
                    .font(.ggBodyMedium)
                    .foregroundStyle(textColor.opacity(0.8))
            }

            if !detail.isEmpty {
                Text(detail)
                    .font(.ggBodyMedium)
                    .foregroundStyle(textColor.opacity(0.7))
            }

            Text(relativeTime)
                .font(.ggLabelMedium)
                .foregroundStyle(textColor.opacity(0.6))
                .padding(.top, GGSpacing.xs)
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text("Last Feeding")
                .font(.ggTitleLarge)
                .foregroundStyle(textColor)

            Text("No feedings recorded yet")
                .font(.ggBodyLarge)
                .foregroundStyle(textColor.opacity(0.7))

            Text("Tap the Feeding button below to log one")
                .font(.ggBodyMedium)
                .foregroundStyle(textColor.opacity(0.5))
        }
    }

    // MARK: - Colors

    private var textColor: Color {
        colorScheme == .dark ? GGColors.onPrimaryDark : GGColors.onPrimary
    }
}

// MARK: - Previews

#Preview("Last Feeding Card") {
    VStack(spacing: GGSpacing.md) {
        LastFeedingCard(
            typeLabel: "Red Bottle",
            timeString: "7:15 AM",
            relativeTime: "3h 12m ago",
            detail: "4.0 oz (Formula)",
            hasData: true
        )

        LastFeedingCard(
            typeLabel: "",
            timeString: "",
            relativeTime: "",
            detail: "",
            hasData: false
        )
    }
    .padding(GGSpacing.pageInsets)
    .background(GGColors.surface)
}
