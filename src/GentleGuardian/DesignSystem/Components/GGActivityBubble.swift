// GGActivityBubble.swift
// GentleGuardian Design System - Quick-Log Chips
//
// secondary-fixed background, oversized (min 48px) for one-handed thumb interaction.
// Icon + label layout with tap animation.
// Used for the Quick Log grid on the home screen.

import SwiftUI

// MARK: - GGActivityBubble

struct GGActivityBubble: View {
    let title: String
    let icon: String
    let tintColor: Color?
    let action: @MainActor () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String,
        tintColor: Color? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            VStack(spacing: GGSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.ggLabelMedium)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: GGSpacing.activityBubbleHeight + GGSpacing.lg)
            .padding(.horizontal, GGSpacing.sm)
            .padding(.vertical, GGSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.75, style: .continuous)
                    .fill(bubbleBackground)
            )
        }
        .buttonStyle(GGBubblePressStyle())
        .accessibilityLabel("Log \(title)")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("quick-log-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    // MARK: - Colors

    private var bubbleBackground: Color {
        if colorScheme == .dark {
            return GGColors.secondaryContainerDark.opacity(0.5)
        }
        return GGColors.secondaryFixed
    }

    private var iconColor: Color {
        if let tintColor {
            return tintColor
        }
        return colorScheme == .dark ? GGColors.secondaryDark : GGColors.onSecondaryContainer
    }

    private var labelColor: Color {
        let colors = GGAdaptiveColors(colorScheme: colorScheme)
        return colors.onSurface
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Press Animation

private struct GGBubblePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Quick Log Grid

/// A convenience grid layout for activity bubbles, matching the home screen design.
struct GGQuickLogGrid: View {
    let bubbles: [QuickLogItem]

    struct QuickLogItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let tintColor: Color?
        let action: @MainActor () -> Void

        init(
            _ title: String,
            icon: String,
            tintColor: Color? = nil,
            action: @escaping @MainActor () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.tintColor = tintColor
            self.action = action
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: GGSpacing.sm),
        GridItem(.flexible(), spacing: GGSpacing.sm),
        GridItem(.flexible(), spacing: GGSpacing.sm),
        GridItem(.flexible(), spacing: GGSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: GGSpacing.sm) {
            ForEach(bubbles) { item in
                GGActivityBubble(
                    item.title,
                    icon: item.icon,
                    tintColor: item.tintColor,
                    action: item.action
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Activity Bubbles") {
    VStack(alignment: .leading, spacing: GGSpacing.md) {
        Text("Quick Log")
            .font(.ggTitleLarge)
            .foregroundStyle(GGColors.onSurface)
            .asymmetricHorizontalPadding()

        GGQuickLogGrid(bubbles: [
            .init("Feeding", icon: "drop.fill", tintColor: GGColors.primary) { },
            .init("Diaper", icon: "tornado", tintColor: GGColors.tertiary) { },
            .init("Sleep", icon: "moon.fill", tintColor: GGColors.secondary) { },
            .init("Activity", icon: "figure.play", tintColor: GGColors.tertiaryContainer) { },
            .init("Health", icon: "heart.fill", tintColor: GGColors.error) { },
            .init("Growth", icon: "chart.line.uptrend.xyaxis", tintColor: GGColors.primary) { },
            .init("Note", icon: "note.text", tintColor: GGColors.onSurfaceVariant) { },
            .init("Tummy Time", icon: "clock.fill", tintColor: GGColors.tertiary) { },
        ])
        .pageHorizontalPadding()
    }
    .padding(.vertical, GGSpacing.lg)
    .background(GGColors.surface)
}
