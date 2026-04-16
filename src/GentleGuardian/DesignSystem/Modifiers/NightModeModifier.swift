// NightModeModifier.swift
// GentleGuardian Design System - Night Mode Environment Modifier
//
// Reads night mode state from environment and shifts all GGColors to dim variants.
// Protects circadian rhythm during nighttime feedings.
// .nightModeAware() modifier propagates night mode colors to the subtree.

import SwiftUI

// MARK: - Night Mode Modifier

struct NightModeModifier: ViewModifier {
    let isNightMode: Bool

    func body(content: Content) -> some View {
        content
            .environment(\.isNightMode, isNightMode)
            .environment(\.ggColors, GGAdaptiveColors(isNightMode: isNightMode))
            .preferredColorScheme(isNightMode ? .dark : nil)
    }
}

// MARK: - Night Mode Aware Modifier (Reads from Environment)

struct NightModeAwareModifier: ViewModifier {
    @Environment(\.isNightMode) private var isNightMode

    func body(content: Content) -> some View {
        content
            .environment(\.ggColors, GGAdaptiveColors(isNightMode: isNightMode))
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the night mode state for this view and all descendants.
    /// Shifts the entire palette to dim tokens for circadian-safe nighttime use.
    ///
    /// - Parameter isNightMode: Whether night mode is active.
    func nightMode(_ isNightMode: Bool) -> some View {
        self.modifier(NightModeModifier(isNightMode: isNightMode))
    }

    /// Makes this view respond to the current night mode environment.
    /// Updates the adaptive color provider based on the current isNightMode state.
    /// Apply this near the root of your view hierarchy.
    func nightModeAware() -> some View {
        self.modifier(NightModeAwareModifier())
    }
}

// MARK: - Previews

#Preview("Night Mode Comparison") {
    HStack(spacing: 0) {
        // Light mode
        VStack(spacing: GGSpacing.md) {
            Text("Day Mode")
                .font(.ggHeadlineMedium)
                .foregroundStyle(GGColors.onSurface)

            GGCard(style: .hero) {
                Text("Last Feeding")
                    .font(.ggTitleLarge)
                    .foregroundStyle(GGColors.onPrimary)
            }

            GGCard(style: .standard) {
                Text("Sleep Log")
                    .font(.ggBodyLarge)
                    .foregroundStyle(GGColors.onSurface)
            }
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GGColors.surface)
        .nightMode(false)

        // Night mode
        VStack(spacing: GGSpacing.md) {
            Text("Night Mode")
                .font(.ggHeadlineMedium)
                .foregroundStyle(GGColors.onSurfaceDim)

            GGCard(style: .hero) {
                Text("Last Feeding")
                    .font(.ggTitleLarge)
                    .foregroundStyle(GGColors.onPrimaryDim)
            }

            GGCard(style: .standard) {
                Text("Sleep Log")
                    .font(.ggBodyLarge)
                    .foregroundStyle(GGColors.onSurfaceDim)
            }
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GGColors.surfaceDim)
        .nightMode(true)
    }
}
