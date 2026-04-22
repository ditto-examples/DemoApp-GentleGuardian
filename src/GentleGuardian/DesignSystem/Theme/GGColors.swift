// GGColors.swift
// GentleGuardian Design System - Color Palette
//
// Rooted in botanical greens, serene aquatic blues, and sun-drenched ambers.
// NO pure black or pure white for text. Use on-surface (#2c3339) or on-background.
// Surface hierarchy uses background color shifts instead of 1px borders.

import SwiftUI

// MARK: - Color Scheme Convenience

extension EnvironmentValues {
    /// Returns true when the system is in dark mode.
    var isDarkMode: Bool {
        self.colorScheme == .dark
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

    // MARK: - Dark Mode Variants (from designs/dark/DESIGN.md)

    static let primaryDark = Color(hex: 0x57F1DB)
    static let onPrimaryDark = Color(hex: 0x003731)
    static let primaryContainerDark = Color(hex: 0x2DD4BF)
    static let onPrimaryContainerDark = Color(hex: 0x00574D)

    static let secondaryDark = Color(hex: 0xBEC6E0)
    static let onSecondaryDark = Color(hex: 0x283044)
    static let secondaryContainerDark = Color(hex: 0x3F465C)
    static let onSecondaryContainerDark = Color(hex: 0xADB4CE)
    static let secondaryFixedDark = Color(hex: 0xDAE2FD)

    static let tertiaryDark = Color(hex: 0xCFDAF2)
    static let onTertiaryDark = Color(hex: 0x263143)
    static let tertiaryContainerDark = Color(hex: 0xB3BED5)
    static let onTertiaryContainerDark = Color(hex: 0x424D61)

    static let errorDark = Color(hex: 0xFFB4AB)
    static let onErrorDark = Color(hex: 0x690005)
    static let errorContainerDark = Color(hex: 0x93000A)
    static let onErrorContainerDark = Color(hex: 0xFFDAD6)

    static let surfaceDark = Color(hex: 0x051424)
    static let backgroundDark = Color(hex: 0x051424)
    static let onSurfaceDark = Color(hex: 0xD4E4FA)
    static let onBackgroundDark = Color(hex: 0xD4E4FA)
    static let onSurfaceVariantDark = Color(hex: 0xBACAC5)

    static let surfaceContainerDark = Color(hex: 0x122131)
    static let surfaceContainerLowDark = Color(hex: 0x0D1C2D)
    static let surfaceContainerHighDark = Color(hex: 0x1C2B3C)
    static let surfaceContainerHighestDark = Color(hex: 0x273647)
    static let surfaceContainerLowestDark = Color(hex: 0x010F1F)
    static let surfaceBrightDark = Color(hex: 0x2C3A4C).opacity(0.85)

    static let outlineDark = Color(hex: 0x859490)
    static let outlineVariantDark = Color(hex: 0x3C4A46)

    static let inverseSurfaceDark = Color(hex: 0xD4E4FA)
    static let inverseOnSurfaceDark = Color(hex: 0x233143)
    static let inversePrimaryDark = Color(hex: 0x006B5F)

    static let surfaceTintDark = Color(hex: 0x3CDDC7)

    // MARK: - Hero Gradient

    /// The ambient gradient from primary to primary-container at ~15 degrees.
    /// Used for hero sections like the Last Feeding card.
    static let heroGradient = LinearGradient(
        colors: [primary, primaryContainer],
        startPoint: UnitPoint(x: 0, y: 0.13),
        endPoint: UnitPoint(x: 1, y: 0.87)
    )

    static let heroGradientDark = LinearGradient(
        colors: [primaryContainerDark.opacity(0.8), primaryDark.opacity(0.4)],
        startPoint: UnitPoint(x: 0, y: 0.13),
        endPoint: UnitPoint(x: 1, y: 0.87)
    )

    // MARK: - Ambient Shadow Color (tinted, never pure black)

    static let ambientShadow = Color(hex: 0x2C3339).opacity(0.06)

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

/// Provides ColorScheme-aware color resolution via the SwiftUI environment.
struct GGAdaptiveColors: Sendable {
    let isDarkMode: Bool

    init(colorScheme: ColorScheme) {
        self.isDarkMode = colorScheme == .dark
    }

    init(isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
    }

    var primary: Color { isDarkMode ? GGColors.primaryDark : GGColors.primary }
    var onPrimary: Color { isDarkMode ? GGColors.onPrimaryDark : GGColors.onPrimary }
    var primaryContainer: Color { isDarkMode ? GGColors.primaryContainerDark : GGColors.primaryContainer }
    var onPrimaryContainer: Color { isDarkMode ? GGColors.onPrimaryContainerDark : GGColors.onPrimaryContainer }

    var secondary: Color { isDarkMode ? GGColors.secondaryDark : GGColors.secondary }
    var onSecondary: Color { isDarkMode ? GGColors.onSecondaryDark : GGColors.onSecondary }
    var secondaryContainer: Color { isDarkMode ? GGColors.secondaryContainerDark : GGColors.secondaryContainer }
    var onSecondaryContainer: Color { isDarkMode ? GGColors.onSecondaryContainerDark : GGColors.onSecondaryContainer }

    var tertiary: Color { isDarkMode ? GGColors.tertiaryDark : GGColors.tertiary }
    var onTertiary: Color { isDarkMode ? GGColors.onTertiaryDark : GGColors.onTertiary }
    var tertiaryContainer: Color { isDarkMode ? GGColors.tertiaryContainerDark : GGColors.tertiaryContainer }
    var onTertiaryContainer: Color { isDarkMode ? GGColors.onTertiaryContainerDark : GGColors.onTertiaryContainer }

    var error: Color { isDarkMode ? GGColors.errorDark : GGColors.error }
    var onError: Color { isDarkMode ? GGColors.onErrorDark : GGColors.onError }
    var errorContainer: Color { isDarkMode ? GGColors.errorContainerDark : GGColors.errorContainer }
    var onErrorContainer: Color { isDarkMode ? GGColors.onErrorContainerDark : GGColors.onErrorContainer }

    var surface: Color { isDarkMode ? GGColors.surfaceDark : GGColors.surface }
    var background: Color { isDarkMode ? GGColors.backgroundDark : GGColors.background }
    var onSurface: Color { isDarkMode ? GGColors.onSurfaceDark : GGColors.onSurface }
    var onBackground: Color { isDarkMode ? GGColors.onBackgroundDark : GGColors.onBackground }
    var onSurfaceVariant: Color { isDarkMode ? GGColors.onSurfaceVariantDark : GGColors.onSurfaceVariant }

    var surfaceContainer: Color { isDarkMode ? GGColors.surfaceContainerDark : GGColors.surfaceContainer }
    var surfaceContainerLow: Color { isDarkMode ? GGColors.surfaceContainerLowDark : GGColors.surfaceContainerLow }
    var surfaceContainerHigh: Color { isDarkMode ? GGColors.surfaceContainerHighDark : GGColors.surfaceContainerHigh }
    var surfaceContainerHighest: Color { isDarkMode ? GGColors.surfaceContainerHighestDark : GGColors.surfaceContainerHighest }
    var surfaceContainerLowest: Color { isDarkMode ? GGColors.surfaceContainerLowestDark : GGColors.surfaceContainerLowest }

    var outline: Color { isDarkMode ? GGColors.outlineDark : GGColors.outline }
    var outlineVariant: Color { isDarkMode ? GGColors.outlineVariantDark : GGColors.outlineVariant }

    var inverseSurface: Color { isDarkMode ? GGColors.inverseSurfaceDark : GGColors.inverseSurface }
    var inverseOnSurface: Color { isDarkMode ? GGColors.inverseOnSurfaceDark : GGColors.inverseOnSurface }
    var inversePrimary: Color { isDarkMode ? GGColors.inversePrimaryDark : GGColors.inversePrimary }

    var heroGradient: LinearGradient { isDarkMode ? GGColors.heroGradientDark : GGColors.heroGradient }
}

// MARK: - Environment-based Adaptive Colors Key

struct AdaptiveColorsKey: EnvironmentKey {
    static let defaultValue = GGAdaptiveColors(isDarkMode: false)
}

extension EnvironmentValues {
    var ggColors: GGAdaptiveColors {
        get { self[AdaptiveColorsKey.self] }
        set { self[AdaptiveColorsKey.self] = newValue }
    }
}
