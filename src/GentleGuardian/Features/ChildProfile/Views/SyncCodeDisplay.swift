import SwiftUI

/// Displays the sync code in a large, easy-to-read character grid format
/// with a copy-to-clipboard button.
///
/// Matches the mockup: characters displayed in an "A B C / 1 2 3" layout
/// with generous spacing for readability.
struct SyncCodeDisplay: View {

    // MARK: - Properties

    let syncCode: String
    let didCopy: Bool
    let onCopy: () -> Void

    @Environment(\.isNightMode) private var isNightMode

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: GGSpacing.md) {
            // Section header
            HStack(spacing: GGSpacing.sm) {
                Image(systemName: "link.circle.fill")
                    .font(.ggTitleLarge)
                    .foregroundStyle(colors.primary)

                Text("Family Sync")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)
            }

            Text("Share this code with partners or caregivers to sync their devices.")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface.opacity(0.7))

            // Code display
            codeGrid

            // Copy button
            GGButton(
                didCopy ? "Copied!" : "Copy",
                variant: .secondary,
                icon: didCopy ? "checkmark" : "doc.on.doc"
            ) {
                onCopy()
            }
        }
    }

    // MARK: - Code Grid

    private var codeGrid: some View {
        let characters = Array(syncCode)
        let midpoint = characters.count / 2

        return VStack(spacing: GGSpacing.sm) {
            // First row (first 3 characters)
            HStack(spacing: GGSpacing.md) {
                ForEach(0..<min(midpoint, characters.count), id: \.self) { index in
                    codeCharacterView(String(characters[index]))
                }
            }

            // Second row (last 3 characters)
            HStack(spacing: GGSpacing.md) {
                ForEach(midpoint..<characters.count, id: \.self) { index in
                    codeCharacterView(String(characters[index]))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.md)
    }

    // MARK: - Individual Character View

    private func codeCharacterView(_ character: String) -> some View {
        Text(character)
            .font(.ggHeadlineLarge)
            .foregroundStyle(colors.onSurface)
            .frame(width: 52, height: 56)
            .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.4)
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}

// MARK: - Previews

#Preview("Sync Code Display") {
    SyncCodeDisplay(
        syncCode: "ABC123",
        didCopy: false,
        onCopy: { }
    )
    .padding(GGSpacing.lg)
    .background(GGColors.surface)
}
