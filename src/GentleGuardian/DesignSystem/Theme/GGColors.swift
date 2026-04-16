// GGColors.swift
// GentleGuardian Design System - Color Palette
//
// Rooted in botanical greens, serene aquatic blues, and sun-drenched ambers.
// NO pure black or pure white for text. Use on-surface (#2c3339) or on-background.
// Surface hierarchy uses background color shifts instead of 1px borders.

import SwiftUI

// MARK: - Night Mode Environment Key

struct NightModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isNightMode: Bool {
        get { self[NightModeKey.self] }
        set { self[NightModeKey.self] = newValue }
    }
}

// MARK: - GGColors

enum GGColors: Sendable {

    // MARK: - Primary (Botanical Greens)

    static let primary = Color(hex: 0x206A5E)
    static let onPrimary = Color(hex: 0xFFFFFF)
    static let primaryContainer = Color(hex: 0xA9F0E0)
    static let onPrimaryContainer = Color(hex: 0x00201A)

    // MARK: - Secondary (Serene Aquatic Blues)

    static let secondary = Color(hex: 0x4A6572)
    static let onSecondary = Color(hex: 0xFFFFFF)
    static let secondaryContainer = Color(hex: 0xC6E7FF)
    static let onSecondaryContainer = Color(hex: 0x275671)
    static let secondaryFixed = Color(hex: 0xD6ECFF)

    // MARK: - Tertiary (Sun-drenched Ambers)

    static let tertiary = Color(hex: 0x7B5800)
    static let onTertiary = Color(hex: 0xFFFFFF)
    static let tertiaryContainer = Color(hex: 0xFFDEA6)
    static let onTertiaryContainer = Color(hex: 0x261A00)

    // MARK: - Error (Calm, not alert-red)

    static let error = Color(hex: 0xBA1A1A)
    static let onError = Color(hex: 0xFFFFFF)
    static let errorContainer = Color(hex: 0xFFDAD6)
    static let onErrorContainer = Color(hex: 0x410002)

    // MARK: - Surface Hierarchy (Stacked paper sheets)

    /// Level 0 (Base): The root canvas
    static let surface = Color(hex: 0xF7F9FD)
    /// Alias for surface
    static let background = Color(hex: 0xF7F9FD)

    /// Level 1 (Sectioning): Defines content areas without borders
    static let surfaceContainer = Color(hex: 0xE9EEF4)
    /// Slightly lower than container
    static let surfaceContainerLow = Color(hex: 0xEFF3F9)

    /// Level 2 (Interaction Hubs): Primary interaction areas
    static let surfaceContainerHigh = Color(hex: 0xDCE3EA)
    /// Alias for Level 2
    static let surfaceContainerHighest = Color(hex: 0xDCE3EA)

    /// Level 3 (Floating Elements): High-elevation cards
    static let surfaceContainerLowest = Color(hex: 0xFFFFFF)

    /// Semi-transparent for glassmorphism
    static let surfaceBright = Color(hex: 0xF7F9FD).opacity(0.85)

    // MARK: - On-Surface (NEVER pure black)

    static let onSurface = Color(hex: 0x2C3339)
    static let onBackground = Color(hex: 0x2C3339)
    static let onSurfaceVariant = Color(hex: 0x3F484F)

    // MARK: - Outline

    static let outline = Color(hex: 0x6F7980)
    /// Used for ghost borders at 15% opacity
    static let outlineVariant = Color(hex: 0xABB3BA)

    // MARK: - Inverse

    static let inverseSurface = Color(hex: 0x2E3135)
    static let inverseOnSurface = Color(hex: 0xEFF1F5)
    static let inversePrimary = Color(hex: 0x8BD4C4)

    // MARK: - Night / Dim Mode Variants

    static let primaryDim = Color(hex: 0x6BBCAC)
    static let onPrimaryDim = Color(hex: 0x00382E)
    static let primaryContainerDim = Color(hex: 0x005145)

    static let secondaryDim = Color(hex: 0x8ECBF0)
    static let onSecondaryDim = Color(hex: 0x0E3C54)
    static let secondaryContainerDim = Color(hex: 0x1D4D68)

    static let tertiaryDim = Color(hex: 0xE6C16A)
    static let onTertiaryDim = Color(hex: 0x3F2E00)
    static let tertiaryContainerDim = Color(hex: 0x594200)

    static let surfaceDim = Color(hex: 0x121619)
    static let onSurfaceDim = Color(hex: 0xC2C7CE)
    static let surfaceContainerDim = Color(hex: 0x1A1E22)
    static let surfaceContainerHighDim = Color(hex: 0x242A2E)
    static let surfaceContainerLowestDim = Color(hex: 0x2A3036)

    static let errorContainerDim = Color(hex: 0x93000A)
    static let onErrorContainerDim = Color(hex: 0xFFB4AB)

    static let outlineVariantDim = Color(hex: 0x3F484F)

    // MARK: - Hero Gradient

    /// The ambient gradient from primary to primary-container at ~15 degrees.
    /// Used for hero sections like the Last Feeding card.
    static let heroGradient = LinearGradient(
        colors: [primary, primaryContainer],
        startPoint: UnitPoint(x: 0, y: 0.13),
        endPoint: UnitPoint(x: 1, y: 0.87)
    )

    static let heroGradientDim = LinearGradient(
        colors: [primaryContainerDim, primaryDim.opacity(0.6)],
        startPoint: UnitPoint(x: 0, y: 0.13),
        endPoint: UnitPoint(x: 1, y: 0.87)
    )

    // MARK: - Ambient Shadow Color (tinted, never pure black)

    static let ambientShadow = Color(hex: 0x2C3339).opacity(0.06)

    // MARK: - Convenience: Adaptive Colors (light/night)

    /// Returns the appropriate color depending on night mode state.
    static func adaptive(light: Color, night: Color, isNight: Bool) -> Color {
        isNight ? night : light
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Adaptive Color Provider

/// Provides night-mode-aware color resolution via the SwiftUI environment.
struct GGAdaptiveColors: Sendable {
    let isNightMode: Bool

    var primary: Color { isNightMode ? GGColors.primaryDim : GGColors.primary }
    var onPrimary: Color { isNightMode ? GGColors.onPrimaryDim : GGColors.onPrimary }
    var primaryContainer: Color { isNightMode ? GGColors.primaryContainerDim : GGColors.primaryContainer }

    var secondary: Color { isNightMode ? GGColors.secondaryDim : GGColors.secondary }
    var onSecondary: Color { isNightMode ? GGColors.onSecondaryDim : GGColors.onSecondary }
    var secondaryContainer: Color { isNightMode ? GGColors.secondaryContainerDim : GGColors.secondaryContainer }
    var onSecondaryContainer: Color { isNightMode ? GGColors.onSecondaryDim : GGColors.onSecondaryContainer }

    var tertiary: Color { isNightMode ? GGColors.tertiaryDim : GGColors.tertiary }
    var onTertiary: Color { isNightMode ? GGColors.onTertiaryDim : GGColors.onTertiary }
    var tertiaryContainer: Color { isNightMode ? GGColors.tertiaryContainerDim : GGColors.tertiaryContainer }

    var surface: Color { isNightMode ? GGColors.surfaceDim : GGColors.surface }
    var onSurface: Color { isNightMode ? GGColors.onSurfaceDim : GGColors.onSurface }
    var surfaceContainer: Color { isNightMode ? GGColors.surfaceContainerDim : GGColors.surfaceContainer }
    var surfaceContainerHigh: Color { isNightMode ? GGColors.surfaceContainerHighDim : GGColors.surfaceContainerHigh }
    var surfaceContainerLowest: Color { isNightMode ? GGColors.surfaceContainerLowestDim : GGColors.surfaceContainerLowest }

    var errorContainer: Color { isNightMode ? GGColors.errorContainerDim : GGColors.errorContainer }
    var onErrorContainer: Color { isNightMode ? GGColors.onErrorContainerDim : GGColors.onErrorContainer }

    var outlineVariant: Color { isNightMode ? GGColors.outlineVariantDim : GGColors.outlineVariant }

    var heroGradient: LinearGradient { isNightMode ? GGColors.heroGradientDim : GGColors.heroGradient }
}

// MARK: - Environment-based Adaptive Colors Key

struct AdaptiveColorsKey: EnvironmentKey {
    static let defaultValue = GGAdaptiveColors(isNightMode: false)
}

extension EnvironmentValues {
    var ggColors: GGAdaptiveColors {
        get { self[AdaptiveColorsKey.self] }
        set { self[AdaptiveColorsKey.self] = newValue }
    }
}
