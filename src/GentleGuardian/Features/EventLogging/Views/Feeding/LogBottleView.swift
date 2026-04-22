import SwiftUI

/// Form for logging a bottle feeding event with quantity, unit, formula type,
/// time picker, and notes.
struct LogBottleView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: LogFeedingViewModel?

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
        .navigationTitle("Log Feeding")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogFeedingViewModel(
                    childId: childId,
                    feedingRepository: FeedingRepository(dittoManager: DittoManager.shared),
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
    private func formContent(viewModel: LogFeedingViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Feeding type picker
                feedingTypePicker(viewModel: viewModel)

                // Type-specific fields
                switch viewModel.feedingType {
                case .bottle:
                    bottleFields(viewModel: viewModel)
                case .breast:
                    breastFields(viewModel: viewModel)
                case .solid:
                    solidFields(viewModel: viewModel)
                }

                // Time picker
                timeSection(viewModel: viewModel)

                // Notes
                notesSection(viewModel: viewModel)

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save button
                GGButton(
                    "Save Feeding",
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

    // MARK: - Feeding Type Picker

    private func feedingTypePicker(viewModel: LogFeedingViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Type")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Picker("Feeding Type", selection: Binding(
                    get: { viewModel.feedingType },
                    set: { viewModel.feedingType = $0 }
                )) {
                    ForEach(FeedingType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Bottle Fields

    private func bottleFields(viewModel: LogFeedingViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Bottle Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                HStack(spacing: GGSpacing.sm) {
                    GGTextField(
                        "Amount",
                        text: Binding(
                            get: { viewModel.bottleQuantity },
                            set: { viewModel.bottleQuantity = $0 }
                        ),
                        keyboardType: .decimalPad
                    )

                    Picker("Unit", selection: Binding(
                        get: { viewModel.bottleUnit },
                        set: { viewModel.bottleUnit = $0 }
                    )) {
                        ForEach(VolumeUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                // Formula type
                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Formula Type (optional)")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    GGTextField(
                        "e.g., Similac Pro-Advance",
                        text: Binding(
                            get: { viewModel.formulaType },
                            set: { viewModel.formulaType = $0 }
                        ),
                        icon: "drop"
                    )
                }
            }
        }
    }

    // MARK: - Breast Fields

    private func breastFields(viewModel: LogFeedingViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Breastfeeding Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Duration (minutes)")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    GGTextField(
                        "Minutes",
                        text: Binding(
                            get: { viewModel.breastDuration },
                            set: { viewModel.breastDuration = $0 }
                        ),
                        icon: "clock",
                        keyboardType: .numberPad
                    )
                }

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Side")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    Picker("Side", selection: Binding(
                        get: { viewModel.breastSide },
                        set: { viewModel.breastSide = $0 }
                    )) {
                        ForEach(BreastSide.allCases, id: \.self) { side in
                            Text(side.displayName).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Solid Fields

    private func solidFields(viewModel: LogFeedingViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Solid Food Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Food Type")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    GGTextField(
                        "e.g., Sweet potato puree",
                        text: Binding(
                            get: { viewModel.solidType },
                            set: { viewModel.solidType = $0 }
                        ),
                        icon: "fork.knife"
                    )
                }

                HStack(spacing: GGSpacing.sm) {
                    GGTextField(
                        "Amount (optional)",
                        text: Binding(
                            get: { viewModel.solidQuantity },
                            set: { viewModel.solidQuantity = $0 }
                        ),
                        keyboardType: .decimalPad
                    )

                    Picker("Unit", selection: Binding(
                        get: { viewModel.solidUnit },
                        set: { viewModel.solidUnit = $0 }
                    )) {
                        ForEach(QuantityUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
        }
    }

    // MARK: - Time Section

    private func timeSection(viewModel: LogFeedingViewModel) -> some View {
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

    private func notesSection(viewModel: LogFeedingViewModel) -> some View {
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

#Preview("Log Bottle") {
    NavigationStack {
        LogBottleView(childId: "test-child")
    }
}
