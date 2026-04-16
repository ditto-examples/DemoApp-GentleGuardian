// GGTypography.swift
// GentleGuardian Design System - Dual-Font Typography
//
// Display & Headlines: Plus Jakarta Sans (fallback: system rounded)
// Body & Labels: Be Vietnam Pro (fallback: system default)
//
// Scale follows the design spec with editorial warmth.
// Never drop below Body-MD (14pt) for critical baby data.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Font Registration

enum GGFontFamily: Sendable {
    /// Display font: Plus Jakarta Sans or system rounded fallback
    case display
    /// Body font: Be Vietnam Pro or system default fallback
    case body
}

// MARK: - Typography Scale

enum GGTypography: Sendable {

    // MARK: Display

    /// 56pt - Milestone celebrations ("Slept 6 hours!")
    static func displayLarge(weight: Font.Weight = .bold) -> Font {
        displayFont(size: 56, weight: weight)
    }

    /// 45pt - Large featured numbers
    static func displayMedium(weight: Font.Weight = .semibold) -> Font {
        displayFont(size: 45, weight: weight)
    }

    /// 36pt - Smaller display usage
    static func displaySmall(weight: Font.Weight = .semibold) -> Font {
        displayFont(size: 36, weight: weight)
    }

    // MARK: Headline

    /// 32pt - Major section headers
    static func headlineLarge(weight: Font.Weight = .bold) -> Font {
        displayFont(size: 32, weight: weight)
    }

    /// 28pt - Standard screen titles
    static func headlineMedium(weight: Font.Weight = .semibold) -> Font {
        displayFont(size: 28, weight: weight)
    }

    /// 24pt - Sub-section headers
    static func headlineSmall(weight: Font.Weight = .semibold) -> Font {
        displayFont(size: 24, weight: weight)
    }

    // MARK: Title

    /// 22pt - Card titles
    static func titleLarge(weight: Font.Weight = .semibold) -> Font {
        displayFont(size: 22, weight: weight)
    }

    /// 16pt - Secondary titles
    static func titleMedium(weight: Font.Weight = .medium) -> Font {
        bodyFont(size: 16, weight: weight)
    }

    /// 14pt - Tertiary titles
    static func titleSmall(weight: Font.Weight = .medium) -> Font {
        bodyFont(size: 14, weight: weight)
    }

    // MARK: Body

    /// 16pt - Default for all parent-facing logs and notes
    static func bodyLarge(weight: Font.Weight = .regular) -> Font {
        bodyFont(size: 16, weight: weight)
    }

    /// 14pt - Minimum for critical baby data
    static func bodyMedium(weight: Font.Weight = .regular) -> Font {
        bodyFont(size: 14, weight: weight)
    }

    /// 12pt - Only for non-critical metadata
    static func bodySmall(weight: Font.Weight = .regular) -> Font {
        bodyFont(size: 12, weight: weight)
    }

    // MARK: Label

    /// 14pt - Button labels, navigation items
    static func labelLarge(weight: Font.Weight = .medium) -> Font {
        bodyFont(size: 14, weight: weight)
    }

    /// 12pt - Chip labels, badges
    static func labelMedium(weight: Font.Weight = .medium) -> Font {
        bodyFont(size: 12, weight: weight)
    }

    /// 11pt - Captions, timestamps
    static func labelSmall(weight: Font.Weight = .medium) -> Font {
        bodyFont(size: 11, weight: weight)
    }

    // MARK: - Font Builders

    /// Attempts to load Plus Jakarta Sans, falls back to system rounded.
    private static func displayFont(size: CGFloat, weight: Font.Weight) -> Font {
        #if canImport(UIKit)
        if let _ = UIFont(name: "PlusJakartaSans-Bold", size: size) {
            let fontName: String
            switch weight {
            case .bold: fontName = "PlusJakartaSans-Bold"
            case .semibold: fontName = "PlusJakartaSans-SemiBold"
            case .medium: fontName = "PlusJakartaSans-Medium"
            default: fontName = "PlusJakartaSans-Regular"
            }
            return .custom(fontName, size: size)
        }
        #endif
        // Fallback: system rounded for friendly, spacious feel
        return .system(size: size, weight: weight, design: .rounded)
    }

    /// Attempts to load Be Vietnam Pro, falls back to system default.
    private static func bodyFont(size: CGFloat, weight: Font.Weight) -> Font {
        #if canImport(UIKit)
        if let _ = UIFont(name: "BeVietnamPro-Regular", size: size) {
            let fontName: String
            switch weight {
            case .bold: fontName = "BeVietnamPro-Bold"
            case .semibold: fontName = "BeVietnamPro-SemiBold"
            case .medium: fontName = "BeVietnamPro-Medium"
            case .light: fontName = "BeVietnamPro-Light"
            default: fontName = "BeVietnamPro-Regular"
            }
            return .custom(fontName, size: size)
        }
        #endif
        // Fallback: system default for high x-height readability
        return .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Font Extension for Convenient Access

extension Font {
    /// 56pt display - for milestone celebrations
    static var ggDisplayLarge: Font { GGTypography.displayLarge() }
    /// 45pt display
    static var ggDisplayMedium: Font { GGTypography.displayMedium() }
    /// 36pt display
    static var ggDisplaySmall: Font { GGTypography.displaySmall() }

    /// 32pt headline
    static var ggHeadlineLarge: Font { GGTypography.headlineLarge() }
    /// 28pt headline - standard screen titles
    static var ggHeadlineMedium: Font { GGTypography.headlineMedium() }
    /// 24pt headline
    static var ggHeadlineSmall: Font { GGTypography.headlineSmall() }

    /// 22pt title
    static var ggTitleLarge: Font { GGTypography.titleLarge() }
    /// 16pt title
    static var ggTitleMedium: Font { GGTypography.titleMedium() }
    /// 14pt title
    static var ggTitleSmall: Font { GGTypography.titleSmall() }

    /// 16pt body - default for logs and notes
    static var ggBodyLarge: Font { GGTypography.bodyLarge() }
    /// 14pt body - minimum for critical baby data
    static var ggBodyMedium: Font { GGTypography.bodyMedium() }
    /// 12pt body - non-critical metadata only
    static var ggBodySmall: Font { GGTypography.bodySmall() }

    /// 14pt label - buttons, nav
    static var ggLabelLarge: Font { GGTypography.labelLarge() }
    /// 12pt label - chips, badges
    static var ggLabelMedium: Font { GGTypography.labelMedium() }
    /// 11pt label - captions, timestamps
    static var ggLabelSmall: Font { GGTypography.labelSmall() }
}
