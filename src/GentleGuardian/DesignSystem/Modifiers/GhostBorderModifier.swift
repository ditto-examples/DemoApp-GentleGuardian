// GhostBorderModifier.swift
// GentleGuardian Design System - Accessibility Ghost Border
//
// outline-variant (#abb3ba) at 15% opacity.
// For dark mode or low-contrast scenarios.
// Ensures content boundaries remain perceivable without visual noise.

import SwiftUI

// MARK: - Ghost Border Modifier

struct GhostBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let opacity: Double

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    init(
        cornerRadius: CGFloat = GGSpacing.cardCornerRadius,
        lineWidth: CGFloat = 1,
        opacity: Double = 0.15
    ) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: lineWidth)
            )
    }

    private var borderColor: Color {
        let baseColor = colorScheme == .dark ? GGColors.outlineVariantDark : GGColors.outlineVariant

        // Increase opacity for accessibility when system requests increased contrast
        let effectiveOpacity: Double
        if contrast == .increased {
            effectiveOpacity = opacity * 3
        } else {
            effectiveOpacity = opacity
        }

        return baseColor.opacity(effectiveOpacity)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a subtle "Ghost Border" for accessibility in dark mode or low-contrast screens.
    ///
    /// Uses `outline-variant` (#abb3ba) at 15% opacity by default.
    /// Automatically increases opacity when the system requests higher contrast.
    ///
    /// - Parameters:
    ///   - cornerRadius: Corner radius matching the shape. Defaults to card corner radius.
    ///   - lineWidth: Border width. Defaults to 1pt.
    ///   - opacity: Base opacity. Defaults to 0.15 per design spec.
    func ghostBorder(
        cornerRadius: CGFloat = GGSpacing.cardCornerRadius,
        lineWidth: CGFloat = 1,
        opacity: Double = 0.15
    ) -> some View {
        self.modifier(
            GhostBorderModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                opacity: opacity
            )
        )
    }
}

// MARK: - Previews

#Preview("Ghost Borders") {
    VStack(spacing: GGSpacing.lg) {
        Text("Card with Ghost Border")
            .font(.ggBodyLarge)
            .foregroundStyle(GGColors.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .surfaceLevel(.floating)
            .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous))
            .ghostBorder()

        Text("No Ghost Border")
            .font(.ggBodyLarge)
            .foregroundStyle(GGColors.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .surfaceLevel(.floating)
            .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous))
    }
    .padding(GGSpacing.lg)
    .background(GGColors.surfaceDark)
}
