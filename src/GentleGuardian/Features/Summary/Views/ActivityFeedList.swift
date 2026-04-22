import SwiftUI

/// Chronological list of all events for a day, sorted by timestamp descending.
///
/// Each row shows the time, an event type icon, a summary, and a category
/// color indicator. Uses GGCard for each row with spacing (no dividers).
struct ActivityFeedList: View {

    let events: [TimelineEvent]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: GGSpacing.sm) {
                ForEach(events) { event in
                    eventRow(event)
                }
            }
            .accessibilityIdentifier("activity-feed-list")
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: TimelineEvent) -> some View {
        GGCard(style: .standard) {
            HStack(spacing: GGSpacing.md) {
                // Time
                Text(event.timeString)
                    .font(.ggTitleSmall)
                    .foregroundStyle(colors.onSurface)
                    .frame(width: 70, alignment: .leading)

                // Category color indicator
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(categoryColor(for: event.category))
                    .frame(width: 4, height: 36)

                // Icon + Content
                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                    HStack(spacing: GGSpacing.sm) {
                        Image(systemName: event.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(categoryColor(for: event.category))

                        Text(event.title)
                            .font(GGTypography.bodyLarge(weight: .medium))
                            .foregroundStyle(colors.onSurface)
                    }

                    if !event.detail.isEmpty {
                        Text(event.detail)
                            .font(.ggBodyMedium)
                            .foregroundStyle(colors.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: GGSpacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))

            Text("No events recorded")
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurfaceVariant)

            Text("Events logged throughout the day will appear here.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.xxl)
    }

    // MARK: - Helpers

    private func categoryColor(for category: EventCategory) -> Color {
        switch category {
        case .feeding:
            return colors.primary
        case .diaper:
            return colors.tertiary
        case .health:
            return colors.error
        case .activity:
            return colors.secondary
        case .sleep:
            return colors.secondary
        case .other:
            return colors.tertiary
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Activity Feed List") {
    ScrollView {
        ActivityFeedList(events: [
            TimelineEvent(
                id: "1",
                timestamp: Date().addingTimeInterval(-3600),
                category: .feeding,
                iconName: "baby.bottle",
                title: "Bottle",
                detail: "4.0 oz (Formula)"
            ),
            TimelineEvent(
                id: "2",
                timestamp: Date().addingTimeInterval(-7200),
                category: .diaper,
                iconName: "drop.fill",
                title: "Pee",
                detail: "Pee - Medium"
            ),
            TimelineEvent(
                id: "3",
                timestamp: Date().addingTimeInterval(-10800),
                category: .activity,
                iconName: "figure.rolling",
                title: "Tummy Time",
                detail: "Tummy Time - 30 min"
            ),
        ])
        .pageHorizontalPadding()
    }
    .background(GGColors.surface)
}
