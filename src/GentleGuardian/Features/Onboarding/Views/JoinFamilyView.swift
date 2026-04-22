import SwiftUI

/// View for joining an existing child's family circle using a 6-character sync code.
///
/// The user enters the sync code, which triggers a Ditto subscription to discover
/// the child document from a nearby peer. Shows loading/search state with timeout.
struct JoinFamilyView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: JoinFamilyViewModel?

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            if let viewModel {
                formContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Join Family")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel?.cancelSearch()
                    dismiss()
                }
                .foregroundStyle(colors.primary)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JoinFamilyViewModel(
                    childRepository: ChildRepository(dittoManager: DittoManager.shared),
                    activeChildState: activeChildState,
                    dittoManager: DittoManager.shared,
                    userSettings: userSettings
                )
            }
        }
        .onChange(of: viewModel?.didComplete ?? false) { _, completed in
            if completed {
                dismiss()
            }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: JoinFamilyViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Caregiver name
                caregiverSection(viewModel: viewModel)

                // Sync code input
                syncCodeSection(viewModel: viewModel)

                // Search state / results
                if viewModel.isSearching {
                    searchingSection(viewModel: viewModel)
                }

                // Found child
                if let child = viewModel.foundChild {
                    foundChildSection(child: child)
                }

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Validate button
                if !viewModel.isSearching && !viewModel.didComplete {
                    GGButton(
                        "Validate Code",
                        variant: .primary,
                        icon: "checkmark.shield",
                        isDisabled: !viewModel.isSyncCodeValid
                    ) {
                        Task {
                            await viewModel.validateAndSearch()
                        }
                    }
                }
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Caregiver Section

    private func caregiverSection(viewModel: JoinFamilyViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Your Name")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Text("Used so other caregivers can identify you in the app.")
                    .font(.ggBodySmall)
                    .foregroundStyle(colors.onSurface.opacity(0.6))

                GGTextField(
                    "Your first and last name",
                    text: Binding(
                        get: { viewModel.userFullName },
                        set: { viewModel.userFullName = $0 }
                    ),
                    icon: "person.fill"
                )
            }
        }
    }

    // MARK: - Sync Code Section

    private func syncCodeSection(viewModel: JoinFamilyViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Sync Code")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Text("Enter the 6-character code from the other caregiver's device.")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))

                GGTextField(
                    "Enter 6-character code",
                    text: Binding(
                        get: { viewModel.syncCode },
                        set: { viewModel.syncCode = $0 }
                    ),
                    icon: "key",
                    keyboardType: .asciiCapable
                )

                if let message = viewModel.syncCodeValidationMessage {
                    Text(message)
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Searching Section

    private func searchingSection(viewModel: JoinFamilyViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(spacing: GGSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(colors.primary)

                Text("Find Nearby Devices")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Text("Searching for a child with code \(viewModel.syncCode)...")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))
                    .multilineTextAlignment(.center)

                if viewModel.searchTimeoutSeconds > 0 {
                    Text("Timeout in \(viewModel.searchTimeoutSeconds)s")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.5))
                }

                GGButton("Cancel Search", variant: .tertiary) {
                    viewModel.cancelSearch()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Found Child Section

    private func foundChildSection(child: Child) -> some View {
        GGCard(style: .hero) {
            VStack(spacing: GGSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(colors.onPrimary)

                Text("Found \(child.firstName)!")
                    .font(.ggTitleLarge)
                    .foregroundStyle(colors.onPrimary)

                Text("Joining family circle...")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onPrimary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(colors.error)

            Text(message)
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Join Family") {
    NavigationStack {
        JoinFamilyView()
            .environment(ActiveChildState())
            .environment(UserSettings())
    }
}
