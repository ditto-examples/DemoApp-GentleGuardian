// GGGradientBackground.swift
// GentleGuardian Design System - Ambient Gradient
//
// Linear gradient from primary (#206a5e) to primary-container (#a9f0e0)
// at a 15-degree angle. Used for hero sections (Last Feeding card, etc.).
// NEVER a flat hex code for hero backgrounds.

import SwiftUI

// MARK: - GGGradientBackground

struct GGGradientBackground: View {
    let style: GradientStyle

    @Environment(\.colorScheme) private var colorScheme

    init(style: GradientStyle = .hero) {
        self.style = style
    }

    var body: some View {
        gradient
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var gradient: some View {
        switch style {
        case .hero:
            heroGradient
        case .subtle:
            subtleGradient
        case .warmAccent:
            warmAccentGradient
        case .fullScreen:
            fullScreenGradient
        }
    }

    // MARK: - Gradient Styles

    /// Primary-to-primary-container at 15 degrees for hero cards
    private var heroGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [GGColors.primaryContainerDark, GGColors.primaryDark.opacity(0.6)]
                : [GGColors.primary, GGColors.primaryContainer],
            startPoint: UnitPoint(x: 0, y: 0.13),
            endPoint: UnitPoint(x: 1, y: 0.87)
        )
    }

    /// A softer version for subtle background areas
    private var subtleGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [GGColors.surfaceContainerDark, GGColors.surfaceDark]
                : [GGColors.surfaceContainerLow, GGColors.surface],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Tertiary warm accent for celebrations/milestones
    private var warmAccentGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [GGColors.tertiaryContainerDark, GGColors.tertiaryDark.opacity(0.4)]
                : [GGColors.tertiary.opacity(0.15), GGColors.tertiaryContainer.opacity(0.6)],
            startPoint: UnitPoint(x: 0.2, y: 0),
            endPoint: UnitPoint(x: 0.8, y: 1)
        )
    }

    /// Full-screen ambient gradient for onboarding or splash screens
    private var fullScreenGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [GGColors.surfaceDark, GGColors.primaryContainerDark.opacity(0.3), GGColors.surfaceDark]
                : [GGColors.surface, GGColors.primaryContainer.opacity(0.2), GGColors.surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Gradient Style Enum

enum GradientStyle: Sendable {
    /// Primary-to-primary-container at 15 degrees (hero cards)
    case hero
    /// Softer surface gradient for subtle backgrounds
    case subtle
    /// Tertiary warm accent for celebrations
    case warmAccent
    /// Full-screen ambient gradient for onboarding
    case fullScreen
}

// MARK: - View Extension

extension View {
    /// Applies an ambient gradient background. Never use flat hex for hero areas.
    func gradientBackground(_ style: GradientStyle = .hero) -> some View {
        self.background(GGGradientBackground(style: style))
    }
}

// MARK: - Previews

#Preview("Gradient Backgrounds") {
    ScrollView {
        VStack(spacing: GGSpacing.lg) {
            RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                .fill(.clear)
                .frame(height: 120)
                .overlay {
                    Text("Hero Gradient")
                        .font(.ggTitleLarge)
                        .foregroundStyle(GGColors.onPrimary)
                }
                .gradientBackground(.hero)
                .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous))

            RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                .fill(.clear)
                .frame(height: 120)
                .overlay {
                    Text("Subtle Gradient")
                        .font(.ggTitleLarge)
                        .foregroundStyle(GGColors.onSurface)
                }
                .gradientBackground(.subtle)
                .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous))

            RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                .fill(.clear)
                .frame(height: 120)
                .overlay {
                    Text("Warm Accent")
                        .font(.ggTitleLarge)
                        .foregroundStyle(GGColors.onSurface)
                }
                .gradientBackground(.warmAccent)
                .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous))
        }
        .padding(GGSpacing.lg)
    }
    .background(GGGradientBackground(style: .fullScreen))
}
