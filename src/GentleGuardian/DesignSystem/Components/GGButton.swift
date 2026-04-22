// GGButton.swift
// GentleGuardian Design System - Button Components
//
// Three styles: Primary (pill), Secondary (container), Tertiary (text-only).
// All with haptic feedback, loading state, disabled state.
// Minimum touch targets of 48pt for exhausted parents.

import SwiftUI

// MARK: - Button Style Enum

enum GGButtonVariant: Sendable {
    /// Solid primary (#206a5e) with white text, pill-shaped
    case primary
    /// Secondary container (#c6e7ff) with on-secondary-container text, no border
    case secondary
    /// No background, primary-colored text, subtle focus state
    case tertiary
}

// MARK: - GGButton

struct GGButton: View {
    let title: String
    let variant: GGButtonVariant
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: @MainActor () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    init(
        _ title: String,
        variant: GGButtonVariant = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading && !isDisabled else { return }
            triggerHaptic()
            action()
        } label: {
            HStack(spacing: GGSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.ggLabelLarge)
                }
                Text(title)
                    .font(.ggLabelLarge)
            }
            .frame(maxWidth: variant == .tertiary ? nil : .infinity)
            .frame(minHeight: GGSpacing.minimumTouchTarget)
            .padding(.horizontal, variant == .tertiary ? GGSpacing.md : GGSpacing.lg)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
        }
        .buttonStyle(GGButtonPressStyle())
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled && !isLoading)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(title)
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        let colors = GGAdaptiveColors(colorScheme: colorScheme)
        switch variant {
        case .primary:
            // In dark mode, use a darker teal background for better text contrast
            return colorScheme == .dark ? GGColors.onPrimaryContainerDark : colors.primary
        case .secondary:
            return colors.secondaryContainer
        case .tertiary:
            return .clear
        }
    }

    private var foregroundColor: Color {
        let colors = GGAdaptiveColors(colorScheme: colorScheme)
        switch variant {
        case .primary:
            // In dark mode, use bright teal text on the dark teal background
            return colorScheme == .dark ? GGColors.primaryDark : colors.onPrimary
        case .secondary:
            return colors.onSecondaryContainer
        case .tertiary:
            return colors.primary
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Press Animation Style

private struct GGButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Button Variants") {
    VStack(spacing: GGSpacing.md) {
        GGButton("Start Feeding", variant: .primary, icon: "drop.fill") { }
        GGButton("View History", variant: .secondary, icon: "clock") { }
        GGButton("Skip", variant: .tertiary) { }
        GGButton("Loading...", variant: .primary, isLoading: true) { }
        GGButton("Disabled", variant: .primary, isDisabled: true) { }
    }
    .padding(GGSpacing.lg)
    .background(GGColors.surface)
}
