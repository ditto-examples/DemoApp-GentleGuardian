import Foundation
import Observation

/// Observable state container for the currently active child and the list of all children.
///
/// This is injected into the SwiftUI environment so that any view can read and
/// react to changes in the active child selection.
@Observable
final class ActiveChildState: @unchecked Sendable {

    // MARK: - Properties

    /// The ID of the currently selected/active child.
    var activeChildId: String? {
        didSet {
            // Persist the selection for next launch
            if let activeChildId {
                UserDefaults.standard.set(activeChildId, forKey: Self.activeChildIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.activeChildIdKey)
            }
        }
    }

    /// All non-archived children known to this device.
    var children: [Child] = []

    // MARK: - Computed Properties

    /// The currently active child, if any.
    var activeChild: Child? {
        children.first { $0.id == activeChildId }
    }

    /// Whether there is at least one child registered.
    var hasChildren: Bool {
        !children.isEmpty
    }

    /// Whether there are multiple children (for showing a child switcher).
    var hasMultipleChildren: Bool {
        children.count > 1
    }

    // MARK: - Constants

    private static let activeChildIdKey = "activeChildId"

    // MARK: - Initialization

    init() {
        // Restore persisted selection
        self.activeChildId = UserDefaults.standard.string(forKey: Self.activeChildIdKey)
    }

    // MARK: - Methods

    /// Updates the children list and ensures the active child ID is valid.
    ///
    /// If the currently active child is no longer in the list, automatically
    /// selects the first available child.
    func updateChildren(_ newChildren: [Child]) {
        children = newChildren

        // Auto-select if needed
        if activeChildId == nil || !children.contains(where: { $0.id == activeChildId }) {
            activeChildId = children.first?.id
        }
    }

    /// Selects a child by ID.
    func selectChild(_ childId: String) {
        guard children.contains(where: { $0.id == childId }) else { return }
        activeChildId = childId
    }
}
