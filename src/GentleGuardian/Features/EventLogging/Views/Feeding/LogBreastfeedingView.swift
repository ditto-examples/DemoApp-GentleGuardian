import SwiftUI

/// Dedicated view for logging a breastfeeding event.
///
/// Provides duration picker, side selection, time picker, and notes.
/// Uses LogFeedingViewModel with breast type pre-selected.
struct LogBreastfeedingView: View {

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
        .navigationTitle("Log Breastfeeding")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogFeedingViewModel(
                    childId: childId,
                    feedingRepository: FeedingRepository(dittoManager: DittoManager.shared),
                    customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared),
                    initialType: .breast
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
                // Duration
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.md) {
                        Text("Duration (minutes)")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

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
                }

                // Side selection
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.sm) {
                        Text("Side")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

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

                // Time picker
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
                        Text(error)
                            .font(.ggBodyMedium)
                            .foregroundStyle(colors.onSurface)
                    }
                    .padding(GGSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
                }

                // Save
                GGButton(
                    "Save Breastfeeding",
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

#Preview("Log Breastfeeding") {
    NavigationStack {
        LogBreastfeedingView(childId: "test-child")
    }
}
