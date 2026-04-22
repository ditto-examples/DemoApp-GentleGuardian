import SwiftUI

/// Sheet for editing or deleting an existing vaccination record.
struct EditVaccinationSheet: View {

    let record: VaccinationRecord
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel
    @State private var showDeleteConfirmation = false

    init(record: VaccinationRecord, vaccinationRepository: VaccinationRepository, child: Child?) {
        self.record = record
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
                                Text(record.displayName)
                                    .font(.ggTitleMedium)
                                    .foregroundStyle(colors.onSurface)
                                if record.vaccineType != VaccineType.other.rawValue {
                                    Text("Dose \(record.doseNumber)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface.opacity(0.6))
                                }
                            }
                        }

                        // Custom fields for "other" type
                        if record.vaccineType == VaccineType.other.rawValue {
                            GGCard(style: .standard) {
                                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                    Text("Vaccine Name")
                                        .font(.ggLabelLarge)
                                        .foregroundStyle(colors.onSurface)

                                    GGTextField(
                                        "Vaccine name",
                                        text: Binding(
                                            get: { viewModel.customVaccineName },
                                            set: { viewModel.customVaccineName = $0 }
                                        ),
                                        icon: "syringe"
                                    )

                                    Text("Description (optional)")
                                        .font(.ggLabelMedium)
                                        .foregroundStyle(colors.onSurface.opacity(0.6))

                                    GGTextField(
                                        "Description",
                                        text: Binding(
                                            get: { viewModel.customVaccineDescription },
                                            set: { viewModel.customVaccineDescription = $0 }
                                        ),
                                        icon: "text.alignleft"
                                    )
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
                                Text("Notes")
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
                            "Save Changes",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving
                        ) {
                            Task {
                                await viewModel.updateRecord(record)
                            }
                        }

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Record")
                                .font(.ggLabelMedium)
                                .foregroundStyle(GGColors.error)
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Edit Record")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
                viewModel.loadRecord(record)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
            .alert("Delete Vaccination Record?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteRecord(record)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the record. The dose will show as not recorded.")
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
