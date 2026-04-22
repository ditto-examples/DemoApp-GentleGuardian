import SwiftUI

/// Horizontal row of compact status cards showing at-a-glance stats.
///
/// Displays sleep duration, diaper status, and feeding count in a
/// horizontally scrollable row of compact GGCards.
struct StatusRow: View {

    let sleepLabel: String
    let diaperLabel: String
    let diaperRelativeTime: String
    let feedingCount: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: GGSpacing.sm) {
            sleepCard
            diaperCard
            feedingCard
        }
    }

    // MARK: - Cards

    private var sleepCard: some View {
        GGCard(style: .compact) {
            VStack(alignment: .leading, spacing: GGSpacing.xs) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(colorScheme == .dark ? GGColors.secondaryDark : GGColors.secondary)

                Text("SLEEP")
                    .font(.ggLabelSmall)
                    .foregroundStyle(GGColors.onSurfaceVariant)
                    .tracking(0.8)

                Text(sleepLabel)
                    .font(.ggTitleMedium)
                    .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)
                    .lineLimit(1)
            }
        }
    }

    private var diaperCard: some View {
        GGCard(style: .compact) {
            VStack(alignment: .leading, spacing: GGSpacing.xs) {
                Image(systemName: "humidity.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(colorScheme == .dark ? GGColors.tertiaryDark : GGColors.tertiary)

                Text("DIAPER")
                    .font(.ggLabelSmall)
                    .foregroundStyle(GGColors.onSurfaceVariant)
                    .tracking(0.8)

                Text(diaperLabel)
                    .font(.ggTitleMedium)
                    .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)
                    .lineLimit(1)

                if !diaperRelativeTime.isEmpty {
                    Text(diaperRelativeTime)
                        .font(.ggLabelSmall)
                        .foregroundStyle(GGColors.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
        }
    }

    private var feedingCard: some View {
        GGCard(style: .compact) {
            VStack(alignment: .leading, spacing: GGSpacing.xs) {
                Image(systemName: "baby.bottle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(colorScheme == .dark ? GGColors.primaryDark : GGColors.primary)

                Text("FEEDINGS")
                    .font(.ggLabelSmall)
                    .foregroundStyle(GGColors.onSurfaceVariant)
                    .tracking(0.8)

                Text("\(feedingCount)")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)

                Text("today")
                    .font(.ggLabelSmall)
                    .foregroundStyle(GGColors.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Previews

#Preview("Status Row") {
    StatusRow(
        sleepLabel: "9h 12m",
        diaperLabel: "Clean",
        diaperRelativeTime: "45m ago",
        feedingCount: 3
    )
    .padding(GGSpacing.pageInsets)
    .background(GGColors.surface)
}
