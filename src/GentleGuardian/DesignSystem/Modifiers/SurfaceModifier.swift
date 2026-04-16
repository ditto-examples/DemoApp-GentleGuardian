// SurfaceModifier.swift
// GentleGuardian Design System - Surface Level Background Modifier
//
// Applies the appropriate background color for each elevation level.
// Uses tonal lift (background color shifts) instead of traditional shadows.
// .surfaceLevel(.container) applies the right background automatically.

import SwiftUI

// MARK: - Surface Level Modifier

struct SurfaceLevelModifier: ViewModifier {
    let level: SurfaceLevel
    let cornerRadius: CGFloat?

    @Environment(\.isNightMode) private var isNightMode

    init(level: SurfaceLevel, cornerRadius: CGFloat? = nil) {
        self.level = level
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        let bgColor = GGElevation.backgroundColor(for: level, isNightMode: isNightMode)

        if let cornerRadius {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(bgColor)
                )
        } else {
            content
                .background(bgColor)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies the surface-level background for the given tonal depth.
    ///
    /// Surface hierarchy (light mode):
    /// - `.base` -> #f7f9fd (root canvas)
    /// - `.container` -> #e9eef4 (sectioning)
    /// - `.containerLow` -> #eff3f9
    /// - `.containerHigh` / `.containerHighest` -> #dce3ea (interaction hubs)
    /// - `.floating` -> #ffffff (high-elevation cards)
    ///
    /// Automatically adapts for night mode via the environment.
    func surfaceLevel(_ level: SurfaceLevel, cornerRadius: CGFloat? = nil) -> some View {
        self.modifier(SurfaceLevelModifier(level: level, cornerRadius: cornerRadius))
    }
}

// MARK: - Previews

#Preview("Surface Levels") {
    VStack(spacing: GGSpacing.md) {
        ForEach(SurfaceLevel.allCases, id: \.rawValue) { level in
            Text(verbatim: "Level: \(level)")
                .font(.ggBodyLarge)
                .foregroundStyle(GGColors.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .surfaceLevel(level, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
        }
    }
    .padding(GGSpacing.lg)
    .background(GGColors.surface)
}
