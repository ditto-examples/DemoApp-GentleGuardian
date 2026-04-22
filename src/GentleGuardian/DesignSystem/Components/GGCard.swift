// GGCard.swift
// GentleGuardian Design System - Card Container
//
// 32pt corner radius for "soft-edge furniture feel".
// NO divider lines (forbidden by design spec).
// Surface level background based on context.
// Generous padding using GGSpacing.lg.

import SwiftUI

// MARK: - Card Style

enum GGCardStyle: Sendable {
    /// Standard card on surface-container-lowest (floating)
    case standard
    /// Hero card with gradient background (e.g., Last Feeding)
    case hero
    /// Subtle card on surface-container (sectioning)
    case subtle
    /// Compact card for grid layouts
    case compact
}

// MARK: - GGCard

struct GGCard<Content: View>: View {
    let style: GGCardStyle
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: GGCardStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardCard
            case .hero:
                heroCard
            case .subtle:
                subtleCard
            case .compact:
                compactCard
            }
        }
    }

    // MARK: - Standard Card

    private var standardCard: some View {
        content
            .padding(GGSpacing.cardInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                    .fill(GGElevation.backgroundColor(for: .floating, colorScheme: colorScheme))
            )
            .ambientShadow()
    }

    // MARK: - Hero Card (Gradient Background)

    private var heroCard: some View {
        content
            .padding(EdgeInsets(
                top: GGSpacing.heroCardPadding,
                leading: GGSpacing.cardPadding,
                bottom: GGSpacing.heroCardPadding,
                trailing: GGSpacing.cardPadding
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark ? GGColors.heroGradientDark : GGColors.heroGradient
                    )
            )
            .ambientShadow()
    }

    // MARK: - Subtle Card (Sectioning)

    private var subtleCard: some View {
        content
            .padding(GGSpacing.cardInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius, style: .continuous)
                    .fill(GGElevation.backgroundColor(for: .container, colorScheme: colorScheme))
            )
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        content
            .padding(GGSpacing.compactCardInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.75, style: .continuous)
                    .fill(GGElevation.backgroundColor(for: .floating, colorScheme: colorScheme))
            )
    }
}

// MARK: - Previews

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: GGSpacing.cardGap) {
            GGCard(style: .hero) {
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Last Feeding")
                        .font(.ggLabelMedium)
                        .foregroundStyle(GGColors.onPrimary.opacity(0.8))
                    Text("8oz Bottle - 7:15 AM")
                        .font(.ggTitleLarge)
                        .foregroundStyle(GGColors.onPrimary)
                }
            }

            GGCard(style: .standard) {
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Sleep Summary")
                        .font(.ggTitleMedium)
                        .foregroundStyle(GGColors.onSurface)
                    Text("9h 12m total today")
                        .font(.ggBodyLarge)
                        .foregroundStyle(GGColors.onSurfaceVariant)
                }
            }

            GGCard(style: .subtle) {
                Text("Activity section")
                    .font(.ggBodyLarge)
                    .foregroundStyle(GGColors.onSurface)
            }

            HStack(spacing: GGSpacing.cardGap) {
                GGCard(style: .compact) {
                    Text("Compact")
                        .font(.ggLabelLarge)
                        .foregroundStyle(GGColors.onSurface)
                }
                GGCard(style: .compact) {
                    Text("Grid")
                        .font(.ggLabelLarge)
                        .foregroundStyle(GGColors.onSurface)
                }
            }
        }
        .padding(GGSpacing.pageInsets)
    }
    .background(GGColors.surface)
}
