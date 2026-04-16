// GGNightModeToggle.swift
// GentleGuardian Design System - Night Mode Switch
//
// Glassmorphic floating toggle for shifting the palette to dim tokens.
// Protects the parent's circadian rhythm during 3 AM feedings.
// Moon/sun icon with animated palette shift.

import SwiftUI

// MARK: - Night Mode State (Observable)

@Observable
final class NightModeState: @unchecked Sendable {
    var isEnabled: Bool = false
}

// MARK: - GGNightModeToggle

struct GGNightModeToggle: View {
    @Binding var isNightMode: Bool

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Button {
            triggerHaptic()
            withAnimation(.easeInOut(duration: 0.4)) {
                isNightMode.toggle()
            }
        } label: {
            ZStack {
                // Background capsule
                Capsule()
                    .fill(backgroundFill)
                    .frame(width: 64, height: 36)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isNightMode
                                    ? GGColors.outlineVariantDim.opacity(0.3)
                                    : GGColors.outlineVariant.opacity(0.15),
                                lineWidth: 1
                            )
                    )

                // Thumb with icon
                Circle()
                    .fill(thumbFill)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: isNightMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(iconColor)
                    }
                    .offset(x: isNightMode ? 14 : -14)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isNightMode)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isNightMode ? "Disable night mode" : "Enable night mode")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Colors

    private var backgroundFill: Color {
        isNightMode
            ? GGColors.surfaceContainerDim
            : GGColors.surfaceContainerHigh
    }

    private var thumbFill: Color {
        isNightMode
            ? GGColors.primaryContainerDim
            : GGColors.primaryContainer
    }

    private var iconColor: Color {
        isNightMode
            ? GGColors.primaryDim
            : GGColors.primary
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Floating Night Mode Toggle (Glassmorphic)

struct GGFloatingNightModeToggle: View {
    @Binding var isNightMode: Bool

    var body: some View {
        GGNightModeToggle(isNightMode: $isNightMode)
            .padding(GGSpacing.sm)
            .background {
                floatingBackground
            }
            .clipShape(Capsule())
            .ambientShadow()
    }

    @ViewBuilder
    private var floatingBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect()
        } else {
            Capsule()
                .fill(
                    isNightMode
                        ? GGColors.surfaceDim.opacity(0.85)
                        : GGColors.surface.opacity(0.9)
                )
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Previews

#Preview("Night Mode Toggle") {
    @Previewable @State var nightMode = false

    ZStack {
        (nightMode ? GGColors.surfaceDim : GGColors.surface)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: nightMode)

        VStack(spacing: GGSpacing.xl) {
            Text("Night Mode")
                .font(.ggHeadlineMedium)
                .foregroundStyle(nightMode ? GGColors.onSurfaceDim : GGColors.onSurface)

            GGNightModeToggle(isNightMode: $nightMode)

            GGFloatingNightModeToggle(isNightMode: $nightMode)
        }
    }
    .environment(\.isNightMode, nightMode)
}
