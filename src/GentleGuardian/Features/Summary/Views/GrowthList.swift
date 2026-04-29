import SwiftUI

/// Cross-day list of growth measurements (height and weight), newest first.
///
/// Tapping a row calls `onSelect` so the caller can present an
/// `EditHealthSheet` pre-filled with the source event's fields.
struct GrowthList: View {

    let events: [HealthEvent]
    let onSelect: (HealthEvent) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: GGSpacing.sm) {
                ForEach(events) { event in
                    Button {
                        onSelect(event)
                    } label: {
                        row(event)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Double tap to edit")
                }
            }
            .accessibilityIdentifier("growth-list")
        }
    }

    // MARK: - Row

    private func row(_ event: HealthEvent) -> some View {
        GGCard(style: .standard) {
            HStack(spacing: GGSpacing.md) {
                Image(systemName: "ruler")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(colors.error)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                    HStack(spacing: GGSpacing.md) {
                        if let h = event.heightValue, let unit = event.heightUnit {
                            metric(label: "Height", value: "\(format(h)) \(unit.displayName)")
                        }
                        if let w = event.weightValue, let unit = event.weightUnit {
                            metric(label: "Weight", value: "\(format(w)) \(unit.displayName)")
                        }
                        if event.heightValue == nil && event.weightValue == nil {
                            Text("Growth")
                                .font(.ggTitleSmall)
                                .foregroundStyle(colors.onSurface)
                        }
                    }

                    Text(DateService.displayDate(from: event.timestamp))
                        .font(.ggLabelSmall)
                        .foregroundStyle(colors.onSurfaceVariant)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.3))
            }
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.ggLabelSmall)
                .foregroundStyle(colors.onSurfaceVariant)
            Text(value)
                .font(GGTypography.bodyLarge(weight: .medium))
                .foregroundStyle(colors.onSurface)
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: GGSpacing.md) {
            Image(systemName: "ruler")
                .font(.system(size: 40))
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))

            Text("No growth measurements")
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurfaceVariant)

            Text("Log a height or weight measurement to start tracking growth.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.xxl)
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Growth List") {
    let sample = HealthEvent(
        childId: "preview",
        type: .growth,
        heightValue: 65.5,
        heightUnit: .cm,
        weightValue: 7.2,
        weightUnit: .kg
    )
    return ScrollView {
        GrowthList(events: [sample]) { _ in }
            .pageHorizontalPadding()
    }
    .background(GGColors.surface)
}
