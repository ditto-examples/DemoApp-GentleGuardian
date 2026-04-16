// GGSpacing.swift
// GentleGuardian Design System - Spacing Scale
//
// Not a rigid 8dp grid. Allows "Negative Space Voids" - large empty areas
// for visual rest. Supports intentional asymmetry for editorial feel.

import SwiftUI

// MARK: - Spacing Scale

enum GGSpacing: Sendable {

    // MARK: - Core Scale

    /// 4pt - Micro spacing (icon-to-text gaps, inline elements)
    static let xs: CGFloat = 4

    /// 8pt - Small spacing (between related items, inner padding)
    static let sm: CGFloat = 8

    /// 16pt - Medium spacing (standard card padding, list gaps)
    static let md: CGFloat = 16

    /// 24pt - Large spacing (section gaps, generous card padding)
    static let lg: CGFloat = 24

    /// 32pt - Extra large (major section separators)
    static let xl: CGFloat = 32

    /// 48pt - "Negative Space Void" (breathing room between major sections)
    static let xxl: CGFloat = 48

    /// 64pt - Maximum void (hero section top padding, milestone celebrations)
    static let xxxl: CGFloat = 64

    // MARK: - Card-Specific Constants

    /// Standard card corner radius (2rem = 32pt, "soft-edge furniture feel")
    static let cardCornerRadius: CGFloat = 32

    /// Card internal padding (generous, using lg)
    static let cardPadding: CGFloat = lg

    /// Standard gap between cards in a list (no dividers - only whitespace)
    static let cardGap: CGFloat = md

    /// Hero card internal padding (even more generous)
    static let heroCardPadding: CGFloat = xl

    // MARK: - Touch Targets

    /// Minimum touch target for exhausted parents (48pt per spec)
    static let minimumTouchTarget: CGFloat = 48

    /// Comfortable button height
    static let buttonHeight: CGFloat = 52

    /// Activity bubble minimum height
    static let activityBubbleHeight: CGFloat = 48

    // MARK: - Navigation

    /// Glass bar height
    static let glassBarHeight: CGFloat = 56

    /// Glass bar horizontal padding
    static let glassBarHorizontalPadding: CGFloat = lg

    // MARK: - Asymmetric Margins (Editorial Feel)

    /// Asymmetric content margins for header text (24px left, 32px right)
    static let asymmetricLeading: CGFloat = 24
    static let asymmetricTrailing: CGFloat = 32

    /// Standard horizontal page margins
    static let pageHorizontal: CGFloat = 20

    /// Section vertical spacing within a scrollable page
    static let sectionGap: CGFloat = xl

    // MARK: - Convenience EdgeInsets

    /// Asymmetric margins for an editorial, high-end feel
    static let asymmetricMargins = EdgeInsets(
        top: 0,
        leading: asymmetricLeading,
        bottom: 0,
        trailing: asymmetricTrailing
    )

    /// Standard page content insets
    static let pageInsets = EdgeInsets(
        top: md,
        leading: pageHorizontal,
        bottom: md,
        trailing: pageHorizontal
    )

    /// Card content insets
    static let cardInsets = EdgeInsets(
        top: cardPadding,
        leading: cardPadding,
        bottom: cardPadding,
        trailing: cardPadding
    )

    /// Compact card content insets (for smaller cards in grids)
    static let compactCardInsets = EdgeInsets(
        top: md,
        leading: md,
        bottom: md,
        trailing: md
    )
}

// MARK: - View Extension for Asymmetric Padding

extension View {
    /// Applies the editorial asymmetric margins from the design spec.
    func asymmetricHorizontalPadding() -> some View {
        self.padding(.leading, GGSpacing.asymmetricLeading)
            .padding(.trailing, GGSpacing.asymmetricTrailing)
    }

    /// Applies standard page horizontal margins.
    func pageHorizontalPadding() -> some View {
        self.padding(.horizontal, GGSpacing.pageHorizontal)
    }

    /// Adds a "Negative Space Void" - generous vertical breathing room.
    func negativeSpaceVoid() -> some View {
        self.padding(.vertical, GGSpacing.xxl)
    }
}
