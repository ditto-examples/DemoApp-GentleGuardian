import SwiftUI

/// Dedicated view for logging a temperature reading.
///
/// Uses LogHealthViewModel with temperature type pre-selected.
struct LogTemperatureView: View {

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
        .navigationTitle("Log Temperature")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogHealthViewModel(
                    childId: childId,
                    healthRepository: HealthRepository(dittoManager: DittoManager.shared),
                    customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared),
                    initialType: .temperature
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
                // Temperature input
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
                    "Save Temperature",
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
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Log Temperature") {
    NavigationStack {
        LogTemperatureView(childId: "test-child")
    }
}
