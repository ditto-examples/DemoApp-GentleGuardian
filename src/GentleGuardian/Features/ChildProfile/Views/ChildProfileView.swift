import SwiftUI

/// Displays the child's profile with avatar, name, age, birthday, sex,
/// prematurity status, sync code, and tracking day settings.
///
/// Matches the child_profile_settings.png mockup with editable fields
/// and a "Save Profile Changes" button.
struct ChildProfileView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.isNightMode) private var isNightMode

    // MARK: - State

    @State private var viewModel = ChildProfileViewModel(
        childRepository: ChildRepository(dittoManager: DittoManager.shared)
    )

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            if viewModel.child != nil {
                profileContent
            } else {
                emptyState
            }
        }
        .navigationTitle("Profile")
        .inlineNavigationBarTitle()
        .onAppear {
            if let child = activeChildState.activeChild {
                viewModel.loadChild(child)
            }
        }
        .onChange(of: activeChildState.activeChild) { _, newChild in
            if let child = newChild {
                viewModel.loadChild(child)
            }
        }
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Avatar and header
                avatarHeader

                // Info cards
                infoSection

                // Sync code
                GGCard(style: .standard) {
                    SyncCodeDisplay(
                        syncCode: viewModel.child?.syncCode ?? "",
                        didCopy: viewModel.didCopySyncCode,
                        onCopy: { viewModel.copySyncCodeToClipboard() }
                    )
                }

                // Tracking day settings
                GGCard(style: .standard) {
                    TrackingDaySettings(
                        startHour: Binding(
                            get: { viewModel.editDayStartHour },
                            set: { viewModel.editDayStartHour = $0 }
                        ),
                        endHour: Binding(
                            get: { viewModel.editDayEndHour },
                            set: { viewModel.editDayEndHour = $0 }
                        )
                    )
                }

                // Vaccination settings
                VaccinationSettingsCard(
                    isTrackingEnabled: Binding(
                        get: { viewModel.editIsVaccinationTrackingEnabled },
                        set: { viewModel.editIsVaccinationTrackingEnabled = $0 }
                    ),
                    selectedRegion: Binding(
                        get: { viewModel.editVaccinationRegion },
                        set: { viewModel.editVaccinationRegion = $0 }
                    ),
                    selectedCountryCode: Binding(
                        get: { viewModel.editVaccinationCountryCode },
                        set: { viewModel.editVaccinationCountryCode = $0 }
                    )
                )

                // Error message
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save confirmation
                if viewModel.didSave {
                    saveBanner
                }

                // Save button
                GGButton(
                    "Save Profile Changes",
                    variant: .primary,
                    icon: "checkmark.circle",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.hasChanges || !viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.saveProfile()
                    }
                }
                .padding(.top, GGSpacing.sm)
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Avatar Header

    private var avatarHeader: some View {
        VStack(spacing: GGSpacing.md) {
            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(colors.primaryContainer)
                    .frame(width: 96, height: 96)

                Text(avatarInitials)
                    .font(.ggHeadlineLarge)
                    .foregroundStyle(colors.primary)
            }
            .ambientShadow()

            // Name
            Text(viewModel.editFirstName)
                .font(.ggHeadlineMedium)
                .foregroundStyle(colors.onSurface)

            // Age
            Text(viewModel.ageDescription)
                .font(.ggBodyLarge)
                .foregroundStyle(colors.onSurface.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.md)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        GGCard(style: .standard) {
            VStack(spacing: GGSpacing.md) {
                // Name field
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("First Name")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    GGTextField(
                        "First name",
                        text: Binding(
                            get: { viewModel.editFirstName },
                            set: { viewModel.editFirstName = $0 }
                        ),
                        icon: "person"
                    )
                }

                // Birthday
                HStack {
                    VStack(alignment: .leading, spacing: GGSpacing.xs) {
                        Text("Birthday")
                            .font(.ggLabelMedium)
                            .foregroundStyle(colors.onSurface.opacity(0.6))

                        Text(DateService.displayDate(from: viewModel.editBirthday))
                            .font(.ggBodyLarge)
                            .foregroundStyle(colors.onSurface)
                    }

                    Spacer()

                    // Sex display
                    VStack(alignment: .trailing, spacing: GGSpacing.xs) {
                        Text("Sex")
                            .font(.ggLabelMedium)
                            .foregroundStyle(colors.onSurface.opacity(0.6))

                        Text(viewModel.editSex.displayName)
                            .font(.ggBodyLarge)
                            .foregroundStyle(colors.onSurface)
                    }
                }

                // Prematurity status
                if viewModel.editIsPremature, let status = viewModel.computedPrematurityStatus {
                    HStack(spacing: GGSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(colors.primary)

                        Text(status.displayName)
                            .font(.ggBodyMedium)
                            .foregroundStyle(colors.onSurface)
                    }
                    .padding(GGSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.4)
                }
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GGColors.error)

            Text(message)
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    // MARK: - Save Banner

    private var saveBanner: some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(colors.primary)

            Text("Profile saved successfully")
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: GGSpacing.md) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(colors.onSurface.opacity(0.4))

            Text("No child selected")
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurface.opacity(0.6))
        }
    }

    // MARK: - Helpers

    private var avatarInitials: String {
        let name = viewModel.editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "?" }
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}

// MARK: - Previews

#Preview("Child Profile") {
    let state = ActiveChildState()
    NavigationStack {
        ChildProfileView()
            .environment(state)
    }
}
