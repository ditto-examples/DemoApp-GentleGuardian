import SwiftUI

/// Dedicated view for logging a solid food feeding event.
///
/// Provides food type selection, quantity with unit picker, time picker, and notes.
/// Uses LogFeedingViewModel with solid type pre-selected.
struct LogSolidsView: View {

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
        .navigationTitle("Log Solid Food")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogFeedingViewModel(
                    childId: childId,
                    feedingRepository: FeedingRepository(dittoManager: DittoManager.shared),
                    customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared),
                    initialType: .solid
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
                // Food type
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.md) {
                        Text("Food Type")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

                        GGTextField(
                            "e.g., Sweet potato puree",
                            text: Binding(
                                get: { viewModel.solidType },
                                set: { viewModel.solidType = $0 }
                            ),
                            icon: "fork.knife"
                        )

                        GGButton("Add New Food", variant: .tertiary, icon: "plus") {
                            viewModel.showAddFoodAlert = true
                        }
                    }
                }
                .alert("Add New Food", isPresented: Binding(
                    get: { viewModel.showAddFoodAlert },
                    set: { viewModel.showAddFoodAlert = $0 }
                )) {
                    TextField("Food name", text: Binding(
                        get: { viewModel.newFoodName },
                        set: { viewModel.newFoodName = $0 }
                    ))
                    Button("Add") {
                        Task { await viewModel.addNewFood() }
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.newFoodName = ""
                    }
                }

                // Quantity
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.sm) {
                        Text("Quantity (optional)")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

                        HStack(spacing: GGSpacing.sm) {
                            GGTextField(
                                "Amount",
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
                    "Save Solid Food",
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

#Preview("Log Solids") {
    NavigationStack {
        LogSolidsView(childId: "test-child")
    }
}
