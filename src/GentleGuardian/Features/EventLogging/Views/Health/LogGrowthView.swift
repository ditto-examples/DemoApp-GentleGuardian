import SwiftUI

/// Dedicated view for logging a growth measurement (height and/or weight).
///
/// Uses LogHealthViewModel with growth type pre-selected.
struct LogGrowthView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isNightMode) private var isNightMode

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
        .navigationTitle("Log Growth")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogHealthViewModel(
                    childId: childId,
                    healthRepository: HealthRepository(dittoManager: DittoManager.shared),
                    customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared),
                    initialType: .growth
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
                // Height
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.md) {
                        Text("Height")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

                        HStack(spacing: GGSpacing.sm) {
                            GGTextField(
                                "Height value",
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
                }

                // Weight
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.md) {
                        Text("Weight")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

                        HStack(spacing: GGSpacing.sm) {
                            GGTextField(
                                "Weight value",
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

                // Time
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

                // Notes
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

                // Error
                if let error = viewModel.errorMessage {
                    HStack(spacing: GGSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(GGColors.error)
                        Text(error).font(.ggBodyMedium).foregroundStyle(colors.onSurface)
                    }
                    .padding(GGSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
                }

                // Save
                GGButton(
                    "Save Growth Measurement",
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

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}

// MARK: - Previews

#Preview("Log Growth") {
    NavigationStack {
        LogGrowthView(childId: "test-child")
    }
}
