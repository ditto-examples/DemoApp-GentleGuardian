import SwiftUI

/// Toolbar menu for switching between children.
///
/// Shows a list of all children with a checkmark next to the active one.
/// Includes an "Add Child" option at the bottom.
struct ChildSelectorMenu: View {

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.isNightMode) private var isNightMode

    /// Callback when "Add Child" is tapped.
    var onAddChild: (() -> Void)?

    var body: some View {
        Menu {
            ForEach(activeChildState.children) { child in
                Button {
                    activeChildState.selectChild(child.id)
                } label: {
                    HStack {
                        Text(child.firstName)
                        if child.id == activeChildState.activeChildId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                onAddChild?()
            } label: {
                Label("Add Child", systemImage: "plus")
            }
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .foregroundStyle(isNightMode ? GGColors.onSurfaceDim : GGColors.onSurfaceVariant)
        }
        .accessibilityLabel("Switch child")
        .accessibilityIdentifier("child-selector-menu")
    }
}

// MARK: - Previews

#Preview("Child Selector") {
    NavigationStack {
        Text("Home")
            .toolbar {
                ToolbarItem(placement: .trailingToolbar) {
                    ChildSelectorMenu()
                }
            }
    }
    .environment(ActiveChildState())
}
