// GGTextField.swift
// GentleGuardian Design System - Text Input
//
// Unfocused: surface-container-high (#dce3ea) background
// Focused: surface-container-lowest (#ffffff) + 2px ghost border of primary
// Rounded corners matching card style. Clear button.
// Placeholder text in on-surface at 50% opacity.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Cross-Platform Keyboard Type

#if os(iOS)
typealias GGKeyboardType = UIKeyboardType
#else
enum GGKeyboardType {
    case `default`
    case asciiCapable
    case numberPad
    case decimalPad
    case emailAddress
    case URL
}
#endif

// MARK: - GGTextField

struct GGTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    #if os(iOS)
    let keyboardType: UIKeyboardType
    #endif

    @FocusState private var isFocused: Bool
    @Environment(\.isNightMode) private var isNightMode

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        keyboardType: GGKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        #if os(iOS)
        self.keyboardType = keyboardType
        #endif
    }

    var body: some View {
        HStack(spacing: GGSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.ggBodyLarge)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
            }

            TextField(placeholder, text: $text)
                .font(.ggBodyLarge)
                .foregroundStyle(textColor)
                #if os(iOS)
                .keyboardType(keyboardType)
                #endif
                .focused($isFocused)
                .tint(accentColor)

            if !text.isEmpty && isFocused {
                Button {
                    text = ""
                    triggerHaptic()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.ggBodyMedium)
                        .foregroundStyle(GGColors.onSurfaceVariant.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, GGSpacing.md)
        .frame(minHeight: GGSpacing.minimumTouchTarget)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous)
                .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 0)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        let colors = GGAdaptiveColors(isNightMode: isNightMode)
        return isFocused ? colors.surfaceContainerLowest : colors.surfaceContainerHigh
    }

    private var borderColor: Color {
        let colors = GGAdaptiveColors(isNightMode: isNightMode)
        return isFocused ? colors.primary : .clear
    }

    private var textColor: Color {
        let colors = GGAdaptiveColors(isNightMode: isNightMode)
        return colors.onSurface
    }

    private var iconColor: Color {
        let colors = GGAdaptiveColors(isNightMode: isNightMode)
        return isFocused ? colors.primary : colors.onSurface.opacity(0.5)
    }

    private var accentColor: Color {
        let colors = GGAdaptiveColors(isNightMode: isNightMode)
        return colors.primary
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Multi-line Variant

struct GGTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat

    @FocusState private var isFocused: Bool
    @Environment(\.isNightMode) private var isNightMode

    init(
        _ placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat = 100
    ) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.ggBodyLarge)
                    .foregroundStyle(GGAdaptiveColors(isNightMode: isNightMode).onSurface.opacity(0.5))
                    .padding(.horizontal, GGSpacing.md)
                    .padding(.top, GGSpacing.sm + 4)
            }

            TextEditor(text: $text)
                .font(.ggBodyLarge)
                .foregroundStyle(GGAdaptiveColors(isNightMode: isNightMode).onSurface)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, GGSpacing.sm)
                .frame(minHeight: minHeight)
        }
        .background(
            isFocused
                ? GGAdaptiveColors(isNightMode: isNightMode).surfaceContainerLowest
                : GGAdaptiveColors(isNightMode: isNightMode).surfaceContainerHigh
        )
        .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous)
                .strokeBorder(
                    isFocused
                        ? GGAdaptiveColors(isNightMode: isNightMode).primary
                        : .clear,
                    lineWidth: isFocused ? 2 : 0
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Previews

#Preview("Text Fields") {
    @Previewable @State var name = ""
    @Previewable @State var notes = ""
    @Previewable @State var filled = "Theodore"

    VStack(spacing: GGSpacing.md) {
        GGTextField("Full Name", text: $name, icon: "person")
        GGTextField("Search...", text: $filled, icon: "magnifyingglass")
        GGTextEditor("Add notes about the feeding...", text: $notes)
    }
    .padding(GGSpacing.lg)
    .background(GGColors.surfaceContainer)
}
