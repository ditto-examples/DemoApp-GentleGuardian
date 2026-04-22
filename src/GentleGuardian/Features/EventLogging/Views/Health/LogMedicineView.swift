import SwiftUI

/// Form for logging a medicine health event with medicine picker,
/// quantity, unit, time picker, and notes.
struct LogMedicineView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: LogHealthViewModel?

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
        .navigationTitle("Log Health")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogHealthViewModel(
                    childId: childId,
                    healthRepository: HealthRepository(dittoManager: DittoManager.shared),
                    customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared)
                )
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: LogHealthViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Health type picker
                healthTypePicker(viewModel: viewModel)

                // Type-specific fields
                switch viewModel.healthType {
                case .medicine:
                    medicineFields(viewModel: viewModel)
                case .temperature:
                    temperatureFields(viewModel: viewModel)
                case .growth:
                    growthFields(viewModel: viewModel)
                }

                // Time
                timeSection(viewModel: viewModel)

                // Notes
                notesSection(viewModel: viewModel)

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save
                GGButton(
                    "Save Health Event",
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

    // MARK: - Health Type Picker

    private func healthTypePicker(viewModel: LogHealthViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Type")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Picker("Health Type", selection: Binding(
                    get: { viewModel.healthType },
                    set: { viewModel.healthType = $0 }
                )) {
                    ForEach(HealthEventType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Medicine Fields

    private func medicineFields(viewModel: LogHealthViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Medicine Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "Medicine name",
                    text: Binding(
                        get: { viewModel.medicineName },
                        set: { viewModel.medicineName = $0 }
                    ),
                    icon: "pill"
                )

                GGButton("Add New Medicine", variant: .tertiary, icon: "plus") {
                    viewModel.showAddMedicineAlert = true
                }

                HStack(spacing: GGSpacing.sm) {
                    GGTextField(
                        "Dosage (optional)",
                        text: Binding(
                            get: { viewModel.medicineQuantity },
                            set: { viewModel.medicineQuantity = $0 }
                        ),
                        keyboardType: .decimalPad
                    )

                    Picker("Unit", selection: Binding(
                        get: { viewModel.medicineUnit },
                        set: { viewModel.medicineUnit = $0 }
                    )) {
                        ForEach(MedicineUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
        }
        .alert("Add New Medicine", isPresented: Binding(
            get: { viewModel.showAddMedicineAlert },
            set: { viewModel.showAddMedicineAlert = $0 }
        )) {
            TextField("Medicine name", text: Binding(
                get: { viewModel.newMedicineName },
                set: { viewModel.newMedicineName = $0 }
            ))
            Button("Add") {
                Task { await viewModel.addNewMedicine() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.newMedicineName = ""
            }
        }
    }

    // MARK: - Temperature Fields

    private func temperatureFields(viewModel: LogHealthViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Temperature")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                HStack(spacing: GGSpacing.sm) {
                    GGTextField(
                        "Temperature",
                        text: Binding(
                            get: { viewModel.temperatureValue },
                            set: { viewModel.temperatureValue = $0 }
                        ),
                        icon: "thermometer",
                        keyboardType: .decimalPad
                    )

                    Picker("Unit", selection: Binding(
                        get: { viewModel.temperatureUnit },
                        set: { viewModel.temperatureUnit = $0 }
                    )) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
    }

    // MARK: - Growth Fields

    private func growthFields(viewModel: LogHealthViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Growth Measurements")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                // Height
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Height (optional)")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    HStack(spacing: GGSpacing.sm) {
                        GGTextField(
                            "Height",
                            text: Binding(
                                get: { viewModel.heightValue },
                                set: { viewModel.heightValue = $0 }
                            ),
                            icon: "ruler",
                            keyboardType: .decimalPad
                        )

                        Picker("Unit", selection: Binding(
                            get: { viewModel.heightUnit },
                            set: { viewModel.heightUnit = $0 }
                        )) {
                            ForEach(HeightUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                }

                // Weight
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Weight (optional)")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    HStack(spacing: GGSpacing.sm) {
                        GGTextField(
                            "Weight",
                            text: Binding(
                                get: { viewModel.weightValue },
                                set: { viewModel.weightValue = $0 }
                            ),
                            icon: "scalemass",
                            keyboardType: .decimalPad
                        )

                        Picker("Unit", selection: Binding(
                            get: { viewModel.weightUnit },
                            set: { viewModel.weightUnit = $0 }
                        )) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                }
            }
        }
    }

    // MARK: - Time Section

    private func timeSection(viewModel: LogHealthViewModel) -> some View {
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

    // MARK: - Notes Section

    private func notesSection(viewModel: LogHealthViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Notes (optional)")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                GGTextEditor(
                    "Any additional notes...",
                    text: Binding(
                        get: { viewModel.notes },
                        set: { viewModel.notes = $0 }
                    ),
                    minHeight: 80
                )
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

#Preview("Log Medicine") {
    NavigationStack {
        LogMedicineView(childId: "test-child")
    }
}
