import SwiftUI

/// Form for logging a custom "other" event with a free-form name,
/// optional duration, description, and time picker.
/// Shows a picker of previously used names when available.
struct LogOtherView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: LogOtherViewModel?

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
        .navigationTitle("Log Other")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                let vm = LogOtherViewModel(
                    childId: childId,
                    otherEventRepository: OtherEventRepository(dittoManager: DittoManager.shared)
                )
                viewModel = vm
                Task { await vm.loadPastNames() }
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: LogOtherViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Past names picker (only if there are past names)
                if !viewModel.pastNames.isEmpty {
                    pastNamesSection(viewModel: viewModel)
                }

                // Name field (required)
                nameSection(viewModel: viewModel)

                // Duration (optional)
                durationSection(viewModel: viewModel)

                // Description (optional)
                descriptionSection(viewModel: viewModel)

                // Time
                timeSection(viewModel: viewModel)

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save
                GGButton(
                    "Save Event",
                    variant: .primary,
                    icon: "checkmark.circle",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task { await viewModel.save() }
                }
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Past Names Section

    private func pastNamesSection(viewModel: LogOtherViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Recent Activities")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Picker(
                    "Select a past activity",
                    selection: Binding(
                        get: { viewModel.name },
                        set: { viewModel.name = $0 }
                    )
                ) {
                    Text("Choose an activity...")
                        .tag("")
                    ForEach(viewModel.pastNames, id: \.self) { pastName in
                        Text(pastName).tag(pastName)
                    }
                }
                .pickerStyle(.menu)
                .tint(colors.primary)
            }
        }
    }

    // MARK: - Name Section

    private func nameSection(viewModel: LogOtherViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Activity Name")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "What are you tracking?",
                    text: Binding(
                        get: { viewModel.name },
                        set: { viewModel.name = $0 }
                    ),
                    icon: "pencil.and.outline"
                )
            }
        }
    }

    // MARK: - Duration Section

    private func durationSection(viewModel: LogOtherViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Duration (minutes, optional)")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "Minutes",
                    text: Binding(
                        get: { viewModel.durationMinutes },
                        set: { viewModel.durationMinutes = $0 }
                    ),
                    icon: "clock",
                    keyboardType: .numberPad
                )
            }
        }
    }

    // MARK: - Description Section

    private func descriptionSection(viewModel: LogOtherViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Description (optional)")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                GGTextEditor(
                    "Any details about this event...",
                    text: Binding(
                        get: { viewModel.eventDescription },
                        set: { viewModel.eventDescription = $0 }
                    ),
                    minHeight: 80
                )
            }
        }
    }

    // MARK: - Time Section

    private func timeSection(viewModel: LogOtherViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Time")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { viewModel.timestamp },
                        set: { viewModel.timestamp = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .tint(colors.primary)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GGColors.error)
            Text(message).font(.ggBodyMedium).foregroundStyle(colors.onSurface)
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

#Preview("Log Other") {
    NavigationStack {
        LogOtherView(childId: "test-child")
    }
}
