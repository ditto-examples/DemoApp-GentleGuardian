import SwiftUI

/// Sheet for logging a custom/ad-hoc vaccination not in the standard schedule.
struct LogOtherVaccineSheet: View {

    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(vaccinationRepository: VaccinationRepository, child: Child?) {
        self.vaccinationRepository = vaccinationRepository
        self.child = child
        _viewModel = State(initialValue: LogVaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        // Vaccine name
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Vaccine Name")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                GGTextField(
                                    "e.g., Yellow Fever",
                                    text: Binding(
                                        get: { viewModel.customVaccineName },
                                        set: { viewModel.customVaccineName = $0 }
                                    ),
                                    icon: "syringe"
                                )
                            }
                        }

                        // Description
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Description (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                GGTextField(
                                    "e.g., Required for travel to Brazil",
                                    text: Binding(
                                        get: { viewModel.customVaccineDescription },
                                        set: { viewModel.customVaccineDescription = $0 }
                                    ),
                                    icon: "text.alignleft"
                                )
                            }
                        }

                        // Date picker
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Date Administered")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                DatePicker(
                                    "Date",
                                    selection: Binding(
                                        get: { viewModel.dateAdministered },
                                        set: { viewModel.dateAdministered = $0 }
                                    ),
                                    in: viewModel.dateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(colors.primary)

                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(colors.primary)
                                    Text("Age: \(viewModel.ageAtDate)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface)
                                }
                            }
                        }

                        // Notes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Notes (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                TextEditor(text: Binding(
                                    get: { viewModel.notes },
                                    set: { viewModel.notes = $0 }
                                ))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(colors.onSurface)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.ggBodySmall)
                                .foregroundStyle(GGColors.error)
                        }

                        // Save button
                        GGButton(
                            "Save",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving,
                            isDisabled: !viewModel.isOtherFormValid
                        ) {
                            Task {
                                await viewModel.saveOther()
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log Other Vaccine")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
