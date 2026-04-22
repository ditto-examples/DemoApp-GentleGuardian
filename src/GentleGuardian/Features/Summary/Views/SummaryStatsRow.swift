import SwiftUI

/// Row of stat cards showing daily totals for the summary screen.
///
/// Displays total feedings, total diapers, and total activities/health events
/// as compact cards with icons and counts.
struct SummaryStatsRow: View {

    let totalFeedings: Int
    let totalDiapers: Int
    let totalActivitiesAndHealth: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: GGSpacing.sm) {
            statCard(
                icon: "baby.bottle.fill",
                count: totalFeedings,
                label: "Total Feedings",
                tintColor: colors.primary
            )

            statCard(
                icon: "humidity.fill",
                count: totalDiapers,
                label: "Total Diapers",
                tintColor: colors.tertiary
            )

            statCard(
                icon: "figure.play",
                count: totalActivitiesAndHealth,
                label: "Activities",
                tintColor: colors.secondary
            )
        }
    }

    // MARK: - Stat Card

    private func statCard(icon: String, count: Int, label: String, tintColor: Color) -> some View {
        GGCard(style: .compact) {
            VStack(alignment: .leading, spacing: GGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(tintColor)

                Text("\(count)")
                    .font(.ggTitleLarge)
                    .foregroundStyle(colors.onSurface)

                Text(label)
                    .font(.ggLabelSmall)
                    .foregroundStyle(colors.onSurfaceVariant)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Colors

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Stats Row") {
    SummaryStatsRow(
        totalFeedings: 6,
        totalDiapers: 8,
        totalActivitiesAndHealth: 3
    )
    .padding(GGSpacing.pageInsets)
    .background(GGColors.surface)
}
