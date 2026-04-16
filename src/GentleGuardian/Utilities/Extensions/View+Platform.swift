import SwiftUI

// MARK: - Cross-Platform View Extensions

extension View {
    /// Applies `.navigationBarTitleDisplayMode(.inline)` on iOS; no-op on macOS.
    @ViewBuilder
    func inlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: - Cross-Platform Toolbar Placement

extension ToolbarItemPlacement {
    /// Returns `.topBarTrailing` on iOS; `.automatic` on macOS.
    static var trailingToolbar: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - Cross-Platform Picker Styles

extension View {
    /// Applies `.pickerStyle(.wheel)` on iOS; `.pickerStyle(.menu)` on macOS.
    @ViewBuilder
    func wheelPickerStyle() -> some View {
        #if os(iOS)
        self.pickerStyle(.wheel)
        #else
        self.pickerStyle(.menu)
        #endif
    }
}
