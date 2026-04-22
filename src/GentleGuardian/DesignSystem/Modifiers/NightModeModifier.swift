// NightModeModifier.swift
// GentleGuardian Design System - Color Scheme Environment Modifier
//
// Reads the system color scheme and propagates adaptive colors to the subtree.
// .colorSchemeAware() modifier propagates the correct GGAdaptiveColors.

import SwiftUI

// MARK: - Color Scheme Aware Modifier

struct ColorSchemeAwareModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.ggColors, GGAdaptiveColors(colorScheme: colorScheme))
    }
}

// MARK: - View Extensions

extension View {
    /// Makes this view respond to the current system color scheme.
    /// Updates the adaptive color provider based on light/dark mode.
    /// Apply this near the root of your view hierarchy.
    func colorSchemeAware() -> some View {
        self.modifier(ColorSchemeAwareModifier())
    }
}

// MARK: - Previews

#Preview("Color Scheme Comparison") {
    HStack(spacing: 0) {
        // Light mode
        VStack(spacing: GGSpacing.md) {
            Text("Light Mode")
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
        .environment(\.colorScheme, .light)

        // Dark mode
        VStack(spacing: GGSpacing.md) {
            Text("Dark Mode")
                .font(.ggHeadlineMedium)
                .foregroundStyle(GGColors.onSurfaceDark)

            GGCard(style: .hero) {
                Text("Last Feeding")
                    .font(.ggTitleLarge)
                    .foregroundStyle(GGColors.onPrimaryDark)
            }

            GGCard(style: .standard) {
                Text("Sleep Log")
                    .font(.ggBodyLarge)
                    .foregroundStyle(GGColors.onSurfaceDark)
            }
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GGColors.surfaceDark)
        .environment(\.colorScheme, .dark)
    }
}
