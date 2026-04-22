import SwiftUI

/// Settings section for configuring the tracking day start and end hours.
///
/// The tracking day defines the boundaries for daily summary calculations.
/// For example, a 6 AM to 6 AM window captures a full parent day.
struct TrackingDaySettings: View {

    // MARK: - Bindings

    @Binding var startHour: Int
    @Binding var endHour: Int

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: GGSpacing.md) {
            // Section header
            HStack(spacing: GGSpacing.sm) {
                Image(systemName: "clock.fill")
                    .font(.ggTitleLarge)
                    .foregroundStyle(colors.primary)

                Text("Tracking Day")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)
            }

            Text("Adjusting these times will shift how your daily summaries are calculated.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface.opacity(0.7))

            // Time pickers
            HStack(spacing: GGSpacing.lg) {
                hourPicker(label: "Start Time", hour: $startHour)
                hourPicker(label: "End Time", hour: $endHour)
            }
        }
    }

    // MARK: - Hour Picker

    private func hourPicker(label: String, hour: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text(label)
                .font(.ggLabelLarge)
                .foregroundStyle(colors.onSurface)

            Picker(label, selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(formatHour(h)).tag(h)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, GGSpacing.md)
            .frame(minHeight: GGSpacing.minimumTouchTarget)
            .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour: Int
        if hour == 0 {
            displayHour = 12
        } else if hour > 12 {
            displayHour = hour - 12
        } else {
            displayHour = hour
        }
        return "\(displayHour):00 \(period)"
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Tracking Day Settings") {
    @Previewable @State var start = 6
    @Previewable @State var end = 6

    TrackingDaySettings(startHour: $start, endHour: $end)
        .padding(GGSpacing.lg)
        .background(GGColors.surface)
}
