import SwiftUI

/// Sheet for editing or deleting an existing health event (medicine, temperature, or growth).
struct EditHealthSheet: View {

    let event: HealthEvent
    let healthRepository: HealthRepository
    let customItemRepository: CustomItemRepository

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogHealthViewModel
    @State private var showDeleteConfirmation = false

    init(event: HealthEvent, healthRepository: HealthRepository, customItemRepository: CustomItemRepository) {
        self.event = event
        self.healthRepository = healthRepository
        self.customItemRepository = customItemRepository
        _viewModel = State(initialValue: LogHealthViewModel(
            existingEvent: event,
            healthRepository: healthRepository,
            customItemRepository: customItemRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        healthTypePicker

                        switch viewModel.healthType {
                        case .medicine:
                            medicineFields
                        case .temperature:
                            temperatureFields
                        case .growth:
                            growthFields
                        }

                        timeSection
                        notesSection

                        if let error = viewModel.errorMessage {
                            errorBanner(message: error)
                        }

                        GGButton(
                            "Save Changes",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isFormValid
                        ) {
                            Task { await viewModel.save() }
                        }

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Entry")
                                .font(.ggLabelMedium)
                                .foregroundStyle(colors.error)
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Edit Health Event")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
            .onChange(of: viewModel.didDelete) { _, deleted in
                if deleted { dismiss() }
            }
            .alert("Delete this health entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the health event from the log.")
            }
        }
    }

    // MARK: - Sections

    private var healthTypePicker: some View {
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

    private var medicineFields: some View {
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
    }

    private var temperatureFields: some View {
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

    private var growthFields: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Growth Measurements")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

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

    private var timeSection: some View {
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

    private var notesSection: some View {
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

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(colors.error)
            Text(message).font(.ggBodyMedium).foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
