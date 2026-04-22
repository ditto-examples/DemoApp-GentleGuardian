// GGGlassBar.swift
// GentleGuardian Design System - Glassmorphic Navigation/Toolbar
//
// Uses iOS 26 .glassEffect() modifier where available.
// Fallback: semi-transparent surface-bright background with backdrop blur (20px).
// For navigation bars and floating action areas.

import SwiftUI

// MARK: - GGGlassBar

struct GGGlassBar<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: GGSpacing.glassBarHeight)
            .padding(.horizontal, GGSpacing.glassBarHorizontalPadding)
            .background { glassBackground }
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect()
        } else {
            Rectangle()
                .fill(backgroundFill)
                .background(.ultraThinMaterial)
        }
    }

    private var backgroundFill: Color {
        if colorScheme == .dark {
            return GGColors.surfaceDark.opacity(0.75)
        }
        return GGColors.surface.opacity(0.85)
    }
}

// MARK: - GGFloatingGlassBar (Bottom Navigation Style)

struct GGFloatingGlassBar<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: GGSpacing.glassBarHeight)
            .padding(.horizontal, GGSpacing.glassBarHorizontalPadding)
            .background { floatingGlassBackground }
            .clipShape(Capsule())
            .ambientShadow()
            .padding(.horizontal, GGSpacing.lg)
    }

    @ViewBuilder
    private var floatingGlassBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect()
        } else {
            Capsule()
                .fill(backgroundFill)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }

    private var backgroundFill: Color {
        if colorScheme == .dark {
            return GGColors.surfaceDark.opacity(0.85)
        }
        return GGColors.surface.opacity(0.9)
    }
}

// MARK: - Tab Bar Item

struct GGTabItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: @MainActor () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: GGSpacing.xs) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 20, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.ggLabelSmall)
            }
            .foregroundStyle(tabColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: GGSpacing.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var tabColor: Color {
        if isSelected {
            return colorScheme == .dark ? GGColors.primaryDark : GGColors.primary
        }
        return colorScheme == .dark ? GGColors.onSurfaceDark.opacity(0.6) : GGColors.onSurfaceVariant.opacity(0.6)
    }
}

// MARK: - Previews

#Preview("Glass Bars") {
    ZStack {
        GGColors.surface.ignoresSafeArea()

        VStack {
            GGGlassBar {
                HStack {
                    Text("Gentle Guardian")
                        .font(.ggTitleMedium)
                        .foregroundStyle(GGColors.onSurface)
                    Spacer()
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundStyle(GGColors.onSurfaceVariant)
                }
            }

            Spacer()

            GGGlassBar {
                HStack(spacing: 0) {
                    GGTabItem(title: "Home", icon: "house", isSelected: true) { }
                    GGTabItem(title: "Summary", icon: "chart.bar", isSelected: false) { }
                    GGTabItem(title: "Settings", icon: "gearshape", isSelected: false) { }
                }
            }
        }
    }
}
