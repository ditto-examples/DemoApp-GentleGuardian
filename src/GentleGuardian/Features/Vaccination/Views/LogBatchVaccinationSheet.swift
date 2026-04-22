import SwiftUI

/// Sheet for batch-logging multiple vaccination doses from a single visit.
struct LogBatchVaccinationSheet: View {

    let doses: [ScheduledDose]
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(doses: [ScheduledDose], vaccinationRepository: VaccinationRepository, child: Child?) {
        self.doses = doses
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
                        // Vaccine checkboxes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Select Vaccines Given")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                ForEach(doses) { dose in
                                    Toggle(isOn: Binding(
                                        get: { viewModel.selectedDoses.contains(dose.id) },
                                        set: { isOn in
                                            if isOn {
                                                viewModel.selectedDoses.insert(dose.id)
                                            } else {
                                                viewModel.selectedDoses.remove(dose.id)
                                            }
                                        }
                                    )) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(dose.abbreviation) (Dose \(dose.doseNumber))")
                                                .font(.ggLabelMedium)
                                                .foregroundStyle(colors.onSurface)
                                            Text(dose.displayName)
                                                .font(.ggBodySmall)
                                                .foregroundStyle(colors.onSurface.opacity(0.6))
                                        }
                                    }
                                    .tint(colors.primary)
                                }
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
                                .foregroundStyle(colors.error)
                        }

                        // Save button
                        GGButton(
                            "Save \(viewModel.selectedDoses.count) Vaccine\(viewModel.selectedDoses.count == 1 ? "" : "s")",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving,
                            isDisabled: viewModel.selectedDoses.isEmpty
                        ) {
                            Task {
                                await viewModel.saveBatch(doses: doses)
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log Visit")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
                viewModel.initBatchSelection(doses: doses)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
