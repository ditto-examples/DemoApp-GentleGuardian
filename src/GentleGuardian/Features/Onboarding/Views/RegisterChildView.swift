import SwiftUI

/// Form view for registering a new child with name, birthday, sex,
/// and optional prematurity information.
///
/// On submit, generates a sync code, creates the Child record via
/// ChildRepository, and updates ActiveChildState.
struct RegisterChildView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: RegisterChildViewModel?

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
        .navigationTitle("Register a New Baby")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(colors.primary)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RegisterChildViewModel(
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
    private func formContent(viewModel: RegisterChildViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Caregiver name
                caregiverSection(viewModel: viewModel)

                // Baby name field
                nameSection(viewModel: viewModel)

                // Birthday picker
                birthdaySection(viewModel: viewModel)

                // Sex picker
                sexSection(viewModel: viewModel)

                // Prematurity toggle
                prematuritySection(viewModel: viewModel)

                // Error message
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Submit button
                GGButton(
                    "Complete Registration",
                    variant: .primary,
                    icon: "checkmark.circle",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.submit()
                    }
                }
                .padding(.top, GGSpacing.md)
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Caregiver Section

    private func caregiverSection(viewModel: RegisterChildViewModel) -> some View {
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

    // MARK: - Name Section

    private func nameSection(viewModel: RegisterChildViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Full Name")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "Baby's first name",
                    text: Binding(
                        get: { viewModel.firstName },
                        set: { viewModel.firstName = $0 }
                    ),
                    icon: "person"
                )

                if let message = viewModel.nameValidationMessage {
                    Text(message)
                        .font(.ggBodySmall)
                        .foregroundStyle(GGColors.error)
                }
            }
        }
    }

    // MARK: - Birthday Section

    private func birthdaySection(viewModel: RegisterChildViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Birthday")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                DatePicker(
                    "Date of Birth",
                    selection: Binding(
                        get: { viewModel.birthday },
                        set: { viewModel.birthday = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(colors.primary)

                if let message = viewModel.birthdayValidationMessage {
                    Text(message)
                        .font(.ggBodySmall)
                        .foregroundStyle(GGColors.error)
                }
            }
        }
    }

    // MARK: - Sex Section

    private func sexSection(viewModel: RegisterChildViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Sex")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Picker("Sex", selection: Binding(
                    get: { viewModel.sex },
                    set: { viewModel.sex = $0 }
                )) {
                    ForEach(Sex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(sex)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Prematurity Section

    private func prematuritySection(viewModel: RegisterChildViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Toggle(isOn: Binding(
                    get: { viewModel.isPremature },
                    set: { viewModel.isPremature = $0 }
                )) {
                    VStack(alignment: .leading, spacing: GGSpacing.xs) {
                        Text("Prematurity")
                            .font(.ggLabelLarge)
                            .foregroundStyle(colors.onSurface)

                        Text("Check if baby was born prematurely, adjustments may apply.")
                            .font(.ggBodySmall)
                            .foregroundStyle(colors.onSurface.opacity(0.6))
                    }
                }
                .tint(colors.primary)

                if viewModel.isPremature {
                    VStack(alignment: .leading, spacing: GGSpacing.sm) {
                        Text("Gestational age at birth (weeks)")
                            .font(.ggBodyMedium)
                            .foregroundStyle(colors.onSurface)

                        Picker("Weeks", selection: Binding(
                            get: { viewModel.prematurityWeeks },
                            set: { viewModel.prematurityWeeks = $0 }
                        )) {
                            ForEach(22...39, id: \.self) { week in
                                Text("\(week) weeks").tag(week)
                            }
                        }
                        .wheelPickerStyle()
                        .frame(height: 120)

                        if let status = viewModel.computedPrematurityStatus {
                            Text(status.displayName)
                                .font(.ggBodyMedium)
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, GGSpacing.md)
                                .padding(.vertical, GGSpacing.xs)
                                .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
                        }
                    }
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

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Register Child") {
    NavigationStack {
        RegisterChildView()
            .environment(ActiveChildState())
            .environment(UserSettings())
    }
}
