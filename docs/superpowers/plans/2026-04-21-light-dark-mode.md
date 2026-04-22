# Light & Dark Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's custom `isNightMode` environment toggle with proper system light/dark mode support using SwiftUI's `@Environment(\.colorScheme)`, mapping the light DESIGN.md palette to light mode and the dark DESIGN.md palette to dark mode.

**Architecture:** The current app uses a manual `isNightMode` boolean propagated via SwiftUI environment. All color resolution flows through `GGAdaptiveColors(isNightMode:)` and direct `isNightMode` ternaries. The plan replaces this with `@Environment(\.colorScheme)` throughout, updates `GGColors` to hold both light and dark hex values from the design specs, and updates `GGAdaptiveColors` to resolve based on `ColorScheme` instead of a boolean. The night mode toggle and its environment key are removed entirely — the system controls the appearance.

**Tech Stack:** SwiftUI, Swift 5, Xcode (iOS 26+ / macOS 26+)

---

## Current State Analysis

The app currently has:
1. A `NightModeKey` environment key (`isNightMode: Bool`) set at the root
2. `GGAdaptiveColors` struct that resolves colors based on `isNightMode`
3. `NightModeModifier` that sets both `isNightMode` and `ggColors` in environment
4. `GGNightModeToggle` / `GGFloatingNightModeToggle` components
5. `NightModeState` observable class
6. ~37 files that read `@Environment(\.isNightMode)` or reference `GGColors.*Dim` directly

The "Dim" colors currently used for night mode do NOT match the dark mode design spec. They are a separate set of muted colors. The dark DESIGN.md defines a full Material Design 3-style dark palette that must replace them.

## Color Mapping (from DESIGN.md files)

### Light Mode (from `designs/light/DESIGN.md`)
These are already the current "day mode" colors in `GGColors`. They stay as-is.

### Dark Mode (from `designs/dark/DESIGN.md`)
These replace the current `*Dim` colors:

| Token | Dark Hex |
|-------|----------|
| surface | #051424 |
| surface-dim | #051424 |
| surface-bright | #2c3a4c |
| surface-container-lowest | #010f1f |
| surface-container-low | #0d1c2d |
| surface-container | #122131 |
| surface-container-high | #1c2b3c |
| surface-container-highest | #273647 |
| on-surface | #d4e4fa |
| on-surface-variant | #bacac5 |
| outline | #859490 |
| outline-variant | #3c4a46 |
| primary | #57f1db |
| on-primary | #003731 |
| primary-container | #2dd4bf |
| on-primary-container | #00574d |
| secondary | #bec6e0 |
| on-secondary | #283044 |
| secondary-container | #3f465c |
| on-secondary-container | #adb4ce |
| tertiary | #cfdaf2 |
| on-tertiary | #263143 |
| tertiary-container | #b3bed5 |
| on-tertiary-container | #424d61 |
| error | #ffb4ab |
| on-error | #690005 |
| error-container | #93000a |
| on-error-container | #ffdad6 |
| background | #051424 |
| on-background | #d4e4fa |
| inverse-surface | #d4e4fa |
| inverse-on-surface | #233143 |
| inverse-primary | #006b5f |
| surface-tint | #3cddc7 |

## File Map

### Files to modify:
- `src/GentleGuardian/DesignSystem/Theme/GGColors.swift` — Replace Dim colors with dark palette; switch `GGAdaptiveColors` from `isNightMode: Bool` to `colorScheme: ColorScheme`; remove `NightModeKey`
- `src/GentleGuardian/DesignSystem/Theme/GGElevation.swift` — Switch from `isNightMode: Bool` params to `colorScheme: ColorScheme`
- `src/GentleGuardian/DesignSystem/Modifiers/NightModeModifier.swift` — Replace with `ColorSchemeAwareModifier` that reads `@Environment(\.colorScheme)`
- `src/GentleGuardian/DesignSystem/Modifiers/SurfaceModifier.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Modifiers/GhostBorderModifier.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGCard.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGButton.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGGlassBar.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGNightModeToggle.swift` — Remove entirely (night mode toggle no longer needed)
- `src/GentleGuardian/DesignSystem/Components/GGActivityBubble.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGTextField.swift` — Switch from `isNightMode` env to `colorScheme` env
- `src/GentleGuardian/DesignSystem/Components/GGGradientBackground.swift` — Switch from `isNightMode` env to `colorScheme` env
- All 25 feature views that reference `isNightMode` — Switch to reading `colorScheme` or using `GGAdaptiveColors` via environment

### Files to remove:
- `src/GentleGuardian/DesignSystem/Components/GGNightModeToggle.swift` — No longer needed

---

## Task 1: Update GGColors with Dark Palette and ColorScheme-Based Resolution

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Theme/GGColors.swift`

This is the foundational task. Everything else depends on it.

- [ ] **Step 1: Replace the NightModeKey with a helper that reads ColorScheme**

In `GGColors.swift`, remove the `NightModeKey` struct and the `isNightMode` environment extension (lines 10-21). Replace with a convenience computed property:

```swift
// MARK: - Color Scheme Convenience

extension EnvironmentValues {
    /// Returns true when the system is in dark mode.
    var isDarkMode: Bool {
        self.colorScheme == .dark
    }
}
```

- [ ] **Step 2: Replace all Dim color definitions with the dark DESIGN.md palette**

Replace the entire `// MARK: - Night / Dim Mode Variants` section (lines 97-120) with the dark palette from the spec:

```swift
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
```

- [ ] **Step 3: Update hero gradients for dark mode**

Replace the existing `heroGradientDim` (line 132-136) with a dark mode variant using the new dark palette:

```swift
static let heroGradientDark = LinearGradient(
    colors: [primaryContainerDark.opacity(0.8), primaryDark.opacity(0.4)],
    startPoint: UnitPoint(x: 0, y: 0.13),
    endPoint: UnitPoint(x: 1, y: 0.87)
)
```

- [ ] **Step 4: Update GGAdaptiveColors to use ColorScheme instead of isNightMode**

Replace the entire `GGAdaptiveColors` struct (lines 164-192) with:

```swift
// MARK: - Adaptive Color Provider

/// Provides color-scheme-aware color resolution.
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
```

- [ ] **Step 5: Update the AdaptiveColorsKey default and environment extension**

Replace lines 196-205 with:

```swift
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
```

- [ ] **Step 6: Remove the old `adaptive()` helper function**

Delete the `adaptive(light:night:isNight:)` static function (lines 144-147) since it referenced the old API.

- [ ] **Step 7: Build to verify GGColors.swift compiles**

Run: `cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src && xcodebuild -project GentleGuardian.xcodeproj -scheme GentleGuardian -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -30`

Expected: Build errors in downstream files referencing `isNightMode` and old Dim names — that's expected and will be fixed in subsequent tasks.

- [ ] **Step 8: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Theme/GGColors.swift
git commit -m "refactor: replace night mode colors with dark DESIGN.md palette and ColorScheme-based resolution"
```

---

## Task 2: Update GGElevation to Use ColorScheme

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Theme/GGElevation.swift`

- [ ] **Step 1: Replace isNightMode parameters with colorScheme**

Update `backgroundColor(for:isNightMode:)` to `backgroundColor(for:colorScheme:)`:

```swift
/// Returns the background color for a given surface level.
static func backgroundColor(for level: SurfaceLevel, colorScheme: ColorScheme = .light) -> Color {
    if colorScheme == .dark {
        return darkBackground(for: level)
    }
    return lightBackground(for: level)
}
```

- [ ] **Step 2: Rename nightBackground to darkBackground and update colors**

Replace the `nightBackground(for:)` method with `darkBackground(for:)` using the dark design spec colors:

```swift
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
```

- [ ] **Step 3: Update the tonalLift view extension**

Replace the `tonalLift` extension:

```swift
/// Applies a tonal lift by setting the background to the appropriate surface level.
func tonalLift(_ level: SurfaceLevel, colorScheme: ColorScheme = .light) -> some View {
    self.background(GGElevation.backgroundColor(for: level, colorScheme: colorScheme))
}
```

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Theme/GGElevation.swift
git commit -m "refactor: update GGElevation to use ColorScheme instead of isNightMode"
```

---

## Task 3: Update NightModeModifier to ColorScheme-Aware Modifier

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Modifiers/NightModeModifier.swift`

- [ ] **Step 1: Replace the entire file contents**

Replace `NightModeModifier.swift` with a modifier that reads `colorScheme` from the environment and injects the appropriate `GGAdaptiveColors`:

```swift
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
        .colorSchemeAware()

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
        .colorSchemeAware()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Modifiers/NightModeModifier.swift
git commit -m "refactor: replace NightModeModifier with ColorSchemeAwareModifier"
```

---

## Task 4: Update SurfaceModifier and GhostBorderModifier

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Modifiers/SurfaceModifier.swift`
- Modify: `src/GentleGuardian/DesignSystem/Modifiers/GhostBorderModifier.swift`

- [ ] **Step 1: Update SurfaceModifier to use colorScheme**

In `SurfaceLevelModifier`, replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

And update the body to use `colorScheme`:

```swift
func body(content: Content) -> some View {
    let bgColor = GGElevation.backgroundColor(for: level, colorScheme: colorScheme)

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
```

- [ ] **Step 2: Update GhostBorderModifier to use colorScheme**

In `GhostBorderModifier`, replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

And update `borderColor`:

```swift
private var borderColor: Color {
    let baseColor = colorScheme == .dark ? GGColors.outlineVariantDark : GGColors.outlineVariant

    let effectiveOpacity: Double
    if contrast == .increased {
        effectiveOpacity = opacity * 3
    } else {
        effectiveOpacity = opacity
    }

    return baseColor.opacity(effectiveOpacity)
}
```

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Modifiers/SurfaceModifier.swift src/GentleGuardian/DesignSystem/Modifiers/GhostBorderModifier.swift
git commit -m "refactor: update SurfaceModifier and GhostBorderModifier to use colorScheme"
```

---

## Task 5: Update Design System Components (GGCard, GGButton, GGGlassBar)

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Components/GGCard.swift`
- Modify: `src/GentleGuardian/DesignSystem/Components/GGButton.swift`
- Modify: `src/GentleGuardian/DesignSystem/Components/GGGlassBar.swift`

- [ ] **Step 1: Update GGCard**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update all `isNightMode` references in the card bodies:
- `GGElevation.backgroundColor(for: .floating, isNightMode: isNightMode)` becomes `GGElevation.backgroundColor(for: .floating, colorScheme: colorScheme)`
- `isNightMode ? GGColors.heroGradientDim : GGColors.heroGradient` becomes `colorScheme == .dark ? GGColors.heroGradientDark : GGColors.heroGradient`
- `GGElevation.backgroundColor(for: .container, isNightMode: isNightMode)` becomes `GGElevation.backgroundColor(for: .container, colorScheme: colorScheme)`

- [ ] **Step 2: Update GGButton**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update `backgroundColor`:
```swift
private var backgroundColor: Color {
    let colors = GGAdaptiveColors(colorScheme: colorScheme)
    switch variant {
    case .primary:
        return colors.primary
    case .secondary:
        return colors.secondaryContainer
    case .tertiary:
        return .clear
    }
}
```

Update `foregroundColor`:
```swift
private var foregroundColor: Color {
    let colors = GGAdaptiveColors(colorScheme: colorScheme)
    switch variant {
    case .primary:
        return colors.onPrimary
    case .secondary:
        return colors.onSecondaryContainer
    case .tertiary:
        return colors.primary
    }
}
```

- [ ] **Step 3: Update GGGlassBar, GGFloatingGlassBar, and GGTabItem**

In all three structs, replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

In `GGGlassBar.backgroundFill`:
```swift
private var backgroundFill: Color {
    if colorScheme == .dark {
        return GGColors.surfaceDark.opacity(0.75)
    }
    return GGColors.surface.opacity(0.85)
}
```

In `GGFloatingGlassBar.backgroundFill`:
```swift
private var backgroundFill: Color {
    if colorScheme == .dark {
        return GGColors.surfaceDark.opacity(0.85)
    }
    return GGColors.surface.opacity(0.9)
}
```

In `GGTabItem.tabColor`:
```swift
private var tabColor: Color {
    if isSelected {
        return colorScheme == .dark ? GGColors.primaryDark : GGColors.primary
    }
    return colorScheme == .dark ? GGColors.onSurfaceDark.opacity(0.6) : GGColors.onSurfaceVariant.opacity(0.6)
}
```

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Components/GGCard.swift src/GentleGuardian/DesignSystem/Components/GGButton.swift src/GentleGuardian/DesignSystem/Components/GGGlassBar.swift
git commit -m "refactor: update GGCard, GGButton, GGGlassBar to use colorScheme"
```

---

## Task 6: Update Remaining Design System Components (ActivityBubble, TextField, GradientBackground)

**Files:**
- Modify: `src/GentleGuardian/DesignSystem/Components/GGActivityBubble.swift`
- Modify: `src/GentleGuardian/DesignSystem/Components/GGTextField.swift`
- Modify: `src/GentleGuardian/DesignSystem/Components/GGGradientBackground.swift`

- [ ] **Step 1: Update GGActivityBubble**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update `bubbleBackground`:
```swift
private var bubbleBackground: Color {
    if colorScheme == .dark {
        return GGColors.secondaryContainerDark.opacity(0.5)
    }
    return GGColors.secondaryFixed
}
```

Update `iconColor`:
```swift
private var iconColor: Color {
    if let tintColor {
        return tintColor
    }
    return colorScheme == .dark ? GGColors.secondaryDark : GGColors.onSecondaryContainer
}
```

Update `labelColor`:
```swift
private var labelColor: Color {
    let colors = GGAdaptiveColors(colorScheme: colorScheme)
    return colors.onSurface
}
```

- [ ] **Step 2: Update GGTextField and GGTextEditor**

In `GGTextField`, replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update all color computed properties to use `GGAdaptiveColors(colorScheme: colorScheme)` instead of `GGAdaptiveColors(isNightMode: isNightMode)`.

In `GGTextEditor`, apply the same change — replace every `GGAdaptiveColors(isNightMode: isNightMode)` with `GGAdaptiveColors(colorScheme: colorScheme)`. Remove the `@Environment(\.isNightMode)` line and add `@Environment(\.colorScheme) private var colorScheme`.

- [ ] **Step 3: Update GGGradientBackground**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update all `isNightMode` ternaries to `colorScheme == .dark`. For example, the hero gradient:

```swift
private var heroGradient: some View {
    LinearGradient(
        colors: colorScheme == .dark
            ? [GGColors.primaryContainerDark.opacity(0.8), GGColors.primaryDark.opacity(0.4)]
            : [GGColors.primary, GGColors.primaryContainer],
        startPoint: UnitPoint(x: 0, y: 0.13),
        endPoint: UnitPoint(x: 1, y: 0.87)
    )
}
```

Apply the same pattern to `subtleGradient`, `warmAccentGradient`, and `fullScreenGradient` — replace `*Dim` color references with their `*Dark` equivalents.

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/DesignSystem/Components/GGActivityBubble.swift src/GentleGuardian/DesignSystem/Components/GGTextField.swift src/GentleGuardian/DesignSystem/Components/GGGradientBackground.swift
git commit -m "refactor: update ActivityBubble, TextField, GradientBackground to use colorScheme"
```

---

## Task 7: Remove GGNightModeToggle

**Files:**
- Remove: `src/GentleGuardian/DesignSystem/Components/GGNightModeToggle.swift`

- [ ] **Step 1: Search for references to GGNightModeToggle and NightModeState**

Run: `grep -r "GGNightModeToggle\|GGFloatingNightModeToggle\|NightModeState" src/GentleGuardian/ --include="*.swift" -l`

Check every file returned. Remove any usage of these types (e.g., if any view embeds the toggle, remove that section). The night mode toggle is replaced by the system's own dark mode setting.

- [ ] **Step 2: Delete GGNightModeToggle.swift**

Remove the file from the Xcode project and the filesystem.

- [ ] **Step 3: Remove any .nightMode() or .nightModeAware() modifier calls**

Search: `grep -r "\.nightMode\|\.nightModeAware" src/GentleGuardian/ --include="*.swift" -l`

Replace `.nightMode(someValue)` calls with `.colorSchemeAware()` (one call near the app root is sufficient). Remove `.nightModeAware()` calls entirely.

- [ ] **Step 4: Commit**

```bash
git rm src/GentleGuardian/DesignSystem/Components/GGNightModeToggle.swift
git add -u src/GentleGuardian/
git commit -m "refactor: remove GGNightModeToggle, NightModeState, and nightMode modifier"
```

---

## Task 8: Update Feature Views — Home Tab

**Files:**
- Modify: `src/GentleGuardian/Features/Home/Views/HomeView.swift`
- Modify: `src/GentleGuardian/Features/Home/Views/LastFeedingCard.swift`
- Modify: `src/GentleGuardian/Features/Home/Views/StatusRow.swift`
- Modify: `src/GentleGuardian/Features/Home/Views/ChildSelectorMenu.swift`
- Modify: `src/GentleGuardian/Features/Home/Views/QuickLogGrid.swift`

- [ ] **Step 1: Update HomeView**

`HomeView` currently uses `GGColors.surface` directly for `.background(GGColors.surface)` and `GGColors.onSurface` / `GGColors.onSurfaceVariant` for text.

Add `@Environment(\.colorScheme) private var colorScheme` and update:
- `.background(GGColors.surface)` becomes `.background(colorScheme == .dark ? GGColors.surfaceDark : GGColors.surface)`
- `GGColors.onSurface` references in text become adaptive:
  ```swift
  .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)
  ```
- `GGColors.onSurfaceVariant` references similarly.

Or more cleanly, use the environment `ggColors`:
```swift
@Environment(\.ggColors) private var colors
```
Then: `.background(colors.surface)`, `.foregroundStyle(colors.onSurface)`, etc.

- [ ] **Step 2: Update LastFeedingCard**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update `textColor`:
```swift
private var textColor: Color {
    colorScheme == .dark ? GGColors.onPrimaryDark : GGColors.onPrimary
}
```

- [ ] **Step 3: Update StatusRow**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update all color ternaries. For example:
- `isNightMode ? GGColors.secondaryDim : GGColors.secondary` becomes `colorScheme == .dark ? GGColors.secondaryDark : GGColors.secondary`
- `isNightMode ? GGColors.onSurfaceDim : GGColors.onSurface` becomes `colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface`
- Same pattern for `tertiaryDim` -> `tertiaryDark`, `primaryDim` -> `primaryDark`

- [ ] **Step 4: Update ChildSelectorMenu**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update: `isNightMode ? GGColors.onSurfaceDim : GGColors.onSurfaceVariant` becomes `colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurfaceVariant`

- [ ] **Step 5: QuickLogGrid — no changes needed**

`QuickLogGrid` uses static `GGColors.primary`, `GGColors.tertiary`, etc. for tint colors. These are passed into `GGActivityBubble` which already handles dark/light internally. No changes needed.

- [ ] **Step 6: Commit**

```bash
git add src/GentleGuardian/Features/Home/Views/
git commit -m "refactor: update Home tab views to use colorScheme"
```

---

## Task 9: Update Feature Views — Summary Tab

**Files:**
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift`
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryStatsRow.swift`
- Modify: `src/GentleGuardian/Features/Summary/Views/ActivityFeedList.swift`

- [ ] **Step 1: Update SummaryView**

Replace `@Environment(\.isNightMode) private var isNightMode` with:

```swift
@Environment(\.colorScheme) private var colorScheme
```

Update all `isNightMode` ternaries:
- `.background(GGColors.surface)` -> `.background(colorScheme == .dark ? GGColors.surfaceDark : GGColors.surface)`
- `isNightMode ? GGColors.onSurfaceDim : GGColors.onSurface` -> `colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface`
- `isNightMode ? GGColors.primaryDim : GGColors.primary` -> `colorScheme == .dark ? GGColors.primaryDark : GGColors.primary`
- `isNightMode ? GGColors.onPrimaryDim : GGColors.onPrimary` -> `colorScheme == .dark ? GGColors.onPrimaryDark : GGColors.onPrimary`

- [ ] **Step 2: Update SummaryStatsRow and ActivityFeedList**

Read each file, replace `@Environment(\.isNightMode)` with `@Environment(\.colorScheme)`, and apply the same `*Dim` -> `*Dark` pattern for all color ternaries.

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/Features/Summary/Views/
git commit -m "refactor: update Summary tab views to use colorScheme"
```

---

## Task 10: Update Feature Views — Child Profile Tab

**Files:**
- Modify: `src/GentleGuardian/Features/ChildProfile/Views/ChildProfileView.swift`
- Modify: `src/GentleGuardian/Features/ChildProfile/Views/SyncCodeDisplay.swift`
- Modify: `src/GentleGuardian/Features/ChildProfile/Views/TrackingDaySettings.swift`

- [ ] **Step 1: Update all three files**

In each file:
1. Replace `@Environment(\.isNightMode) private var isNightMode` with `@Environment(\.colorScheme) private var colorScheme`
2. Replace all `isNightMode ? GGColors.*Dim : GGColors.*` ternaries with `colorScheme == .dark ? GGColors.*Dark : GGColors.*`
3. Replace any `GGAdaptiveColors(isNightMode: isNightMode)` with `GGAdaptiveColors(colorScheme: colorScheme)`

- [ ] **Step 2: Commit**

```bash
git add src/GentleGuardian/Features/ChildProfile/Views/
git commit -m "refactor: update Child Profile tab views to use colorScheme"
```

---

## Task 11: Update Feature Views — Onboarding

**Files:**
- Modify: `src/GentleGuardian/Features/Onboarding/Views/WelcomeView.swift`
- Modify: `src/GentleGuardian/Features/Onboarding/Views/RegisterChildView.swift`
- Modify: `src/GentleGuardian/Features/Onboarding/Views/JoinFamilyView.swift`

- [ ] **Step 1: Update all three onboarding views**

In each file:
1. Replace `@Environment(\.isNightMode) private var isNightMode` with `@Environment(\.colorScheme) private var colorScheme`
2. Update `colors` computed property from `GGAdaptiveColors(isNightMode: isNightMode)` to `GGAdaptiveColors(colorScheme: colorScheme)`

For `WelcomeView`, the `colors` helper on line 129-131 becomes:
```swift
private var colors: GGAdaptiveColors {
    GGAdaptiveColors(colorScheme: colorScheme)
}
```

- [ ] **Step 2: Commit**

```bash
git add src/GentleGuardian/Features/Onboarding/Views/
git commit -m "refactor: update Onboarding views to use colorScheme"
```

---

## Task 12: Update Feature Views — Event Logging

**Files:**
- Modify: `src/GentleGuardian/Features/EventLogging/Views/LogEventSheet.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Feeding/LogBottleView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Feeding/LogBreastfeedingView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Feeding/LogSolidsView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Diaper/LogDiaperView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Health/LogTemperatureView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Health/LogMedicineView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Health/LogGrowthView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Sleep/LogSleepView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Other/LogOtherView.swift`
- Modify: `src/GentleGuardian/Features/EventLogging/Views/Activity/LogActivityView.swift`

- [ ] **Step 1: Update all event logging views**

For every file in the list above, apply the same mechanical transformation:
1. Replace `@Environment(\.isNightMode) private var isNightMode` with `@Environment(\.colorScheme) private var colorScheme`
2. Replace `isNightMode ? GGColors.*Dim : GGColors.*` with `colorScheme == .dark ? GGColors.*Dark : GGColors.*`
3. Replace `GGAdaptiveColors(isNightMode: isNightMode)` with `GGAdaptiveColors(colorScheme: colorScheme)`

- [ ] **Step 2: Commit**

```bash
git add src/GentleGuardian/Features/EventLogging/
git commit -m "refactor: update Event Logging views to use colorScheme"
```

---

## Task 13: Update Feature Views — Information Tab

**Files:**
- Modify: `src/GentleGuardian/Features/Information/Views/InformationView.swift`

- [ ] **Step 1: Update InformationView**

Same transformation:
1. Replace `@Environment(\.isNightMode) private var isNightMode` with `@Environment(\.colorScheme) private var colorScheme`
2. Replace all `isNightMode` color ternaries with `colorScheme == .dark` equivalents.

- [ ] **Step 2: Commit**

```bash
git add src/GentleGuardian/Features/Information/
git commit -m "refactor: update Information tab to use colorScheme"
```

---

## Task 14: Wire Up ColorSchemeAware at the App Root

**Files:**
- Modify: `src/GentleGuardian/App/GentleGuardianApp.swift`

- [ ] **Step 1: Add .colorSchemeAware() to the root view**

In `GentleGuardianApp.body`, add `.colorSchemeAware()` to the Group so the `ggColors` environment is populated from the system color scheme:

```swift
var body: some Scene {
    WindowGroup {
        Group {
            if let initError {
                InitializationErrorView(error: initError) {
                    self.initError = nil
                    Task {
                        await initializeDitto()
                    }
                }
            } else if !isInitialized {
                ProgressView("Starting Gentle Guardian...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentView(
                    feedingRepository: feedingRepository,
                    diaperRepository: diaperRepository,
                    healthRepository: healthRepository,
                    activityRepository: activityRepository,
                    sleepRepository: sleepRepository,
                    otherEventRepository: otherEventRepository
                )
            }
        }
        .colorSchemeAware()
        .environment(activeChildState)
        .environment(userSettings)
        .task {
            await initializeDitto()
        }
    }
}
```

- [ ] **Step 2: Remove any NightModeState or isNightMode @State from the app root**

If there is a `@State private var nightModeState` or similar, remove it. The system now controls dark/light.

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/App/GentleGuardianApp.swift
git commit -m "feat: wire up colorSchemeAware modifier at app root"
```

---

## Task 15: Update ChildProfileViewModel (if it references night mode)

**Files:**
- Modify: `src/GentleGuardian/Features/ChildProfile/ViewModels/ChildProfileViewModel.swift`

- [ ] **Step 1: Check for isNightMode references**

Read the file. If it references `isNightMode` or `NightModeState`, remove those references. ViewModels should not hold color state — that's the view layer's job via `@Environment(\.colorScheme)`.

- [ ] **Step 2: Commit if changes were made**

```bash
git add src/GentleGuardian/Features/ChildProfile/ViewModels/ChildProfileViewModel.swift
git commit -m "refactor: remove night mode references from ChildProfileViewModel"
```

---

## Task 16: Full Build and Verification

- [ ] **Step 1: Build the project**

Run: `cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src && xcodebuild -project GentleGuardian.xcodeproj -scheme GentleGuardian -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -50`

Expected: BUILD SUCCEEDED with zero errors.

- [ ] **Step 2: Search for any remaining isNightMode references**

Run: `grep -r "isNightMode\|NightModeKey\|NightModeState\|nightMode\b\|Dim\b" src/GentleGuardian/ --include="*.swift" -l`

Expected: No matches (or only comments/documentation). If any remain, fix them.

- [ ] **Step 3: Search for any remaining *Dim color references**

Run: `grep -r "primaryDim\|secondaryDim\|tertiaryDim\|surfaceDim\|onSurfaceDim\|onPrimaryDim\|onSecondaryDim\|onTertiaryDim\|surfaceContainerDim\|surfaceContainerHighDim\|surfaceContainerLowestDim\|errorContainerDim\|onErrorContainerDim\|outlineVariantDim\|heroGradientDim" src/GentleGuardian/ --include="*.swift" -l`

Expected: No matches. All `*Dim` references should have been replaced with `*Dark`.

- [ ] **Step 4: Verify dark mode in simulator**

Launch the app in the simulator. Toggle Settings > Developer > Dark Appearance (or use `xcrun simctl ui booted appearance dark`). Verify:
- Backgrounds change to deep navy (#051424)
- Text becomes light (#d4e4fa)
- Primary teal shifts to bright cyan-teal (#57f1db)
- Cards use appropriate dark surface containers
- Hero gradient adapts to dark palette
- Tab bar adapts correctly

Toggle back to light. Verify original light palette is intact.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: clean up any remaining night mode references"
```
