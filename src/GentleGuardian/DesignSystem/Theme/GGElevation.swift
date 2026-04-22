// GGElevation.swift
// GentleGuardian Design System - Tonal Depth System
//
// Depth is felt, not seen. No traditional drop shadows.
// Uses "Tonal Lift" - background color shifts to convey layering.
// Ambient shadows only for floating elements, tinted with on-surface, never pure black.

import SwiftUI

// MARK: - Surface Level

/// Defines the tonal depth level of a surface in the UI hierarchy.
/// Higher levels appear "closer" to the user through lighter backgrounds.
enum SurfaceLevel: Int, Sendable, CaseIterable {
    /// Level 0: Root canvas (`surface` / `background` - #f7f9fd)
    case base = 0
    /// Level 1: Sectioning areas (`surface-container` - #e9eef4)
    case container = 1
    /// Lower container variant
    case containerLow = 2
    /// Level 2: Interaction hubs (`surface-container-highest` - #dce3ea)
    case containerHigh = 3
    /// Alias for containerHigh
    case containerHighest = 4
    /// Level 3: Floating elements (`surface-container-lowest` - #ffffff)
    case floating = 5
}

// MARK: - GGElevation

enum GGElevation: Sendable {

    /// Returns the background color for a given surface level.
    static func backgroundColor(for level: SurfaceLevel, colorScheme: ColorScheme = .light) -> Color {
        if colorScheme == .dark {
            return darkBackground(for: level)
        }
        return lightBackground(for: level)
    }

    private static func lightBackground(for level: SurfaceLevel) -> Color {
        switch level {
        case .base:
            return GGColors.surface
        case .container:
            return GGColors.surfaceContainer
        case .containerLow:
            return GGColors.surfaceContainerLow
        case .containerHigh, .containerHighest:
            return GGColors.surfaceContainerHigh
        case .floating:
            return GGColors.surfaceContainerLowest
        }
    }

    private static func darkBackground(for level: SurfaceLevel) -> Color {
        switch level {
        case .base:
            return GGColors.surfaceDark
        case .container:
            return GGColors.surfaceContainerDark
        case .containerLow:
            return GGColors.surfaceContainerLowDark
        case .containerHigh, .containerHighest:
            return GGColors.surfaceContainerHighDark
        case .floating:
            return GGColors.surfaceContainerLowestDark
        }
    }

    // MARK: - Ambient Shadow

    /// Ambient shadow for floating elements.
    /// `box-shadow: 0 12px 32px rgba(44, 51, 57, 0.06)`
    /// The shadow color is tinted on-surface, never pure black.
    static let ambientShadowColor = Color(hex: 0x2C3339).opacity(0.06)
    static let ambientShadowRadius: CGFloat = 32
    static let ambientShadowY: CGFloat = 12
}

// MARK: - View Extension for Tonal Lift

extension View {
    /// Applies a tonal lift by setting the background to the appropriate surface level.
    /// This is the primary way to convey depth - no traditional shadows needed.
    func tonalLift(_ level: SurfaceLevel, colorScheme: ColorScheme = .light) -> some View {
        self.background(GGElevation.backgroundColor(for: level, colorScheme: colorScheme))
    }

    /// Adds the ambient shadow for floating elements (e.g., FABs, floating log buttons).
    /// Only use when a physical "floating" impression is needed beyond tonal lift.
    func ambientShadow() -> some View {
        self.shadow(
            color: GGElevation.ambientShadowColor,
            radius: GGElevation.ambientShadowRadius / 2,
            x: 0,
            y: GGElevation.ambientShadowY
        )
    }
}
