import SwiftUI

/// Sheet for logging a single scheduled vaccination dose.
struct LogVaccinationSheet: View {

    let dose: ScheduledDose
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(dose: ScheduledDose, vaccinationRepository: VaccinationRepository, child: Child?) {
        self.dose = dose
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
                        // Vaccine info
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text(dose.abbreviation)
                                    .font(.ggTitleMedium)
                                    .foregroundStyle(colors.onSurface)
                                Text("\(dose.displayName) \u{00B7} Dose \(dose.doseNumber)")
                                    .font(.ggBodyMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))
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

                                // Age at date
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
                            "Save",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving
                        ) {
                            Task {
                                await viewModel.saveIndividual(dose: dose)
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log \(dose.abbreviation)")
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
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
