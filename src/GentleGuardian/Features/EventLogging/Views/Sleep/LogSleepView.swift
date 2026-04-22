import SwiftUI

/// Form for logging a sleep event with start time, end time,
/// computed duration display, and optional notes.
struct LogSleepView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: LogSleepViewModel?

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
        .navigationTitle("Log Sleep")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogSleepViewModel(
                    childId: childId,
                    sleepRepository: SleepRepository(dittoManager: DittoManager.shared)
                )
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: LogSleepViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Start time
                startTimeSection(viewModel: viewModel)

                // End time
                endTimeSection(viewModel: viewModel)

                // Duration display
                durationSection(viewModel: viewModel)

                // Notes
                notesSection(viewModel: viewModel)

                // Validation error
                if let message = viewModel.timeValidationMessage {
                    errorBanner(message: message)
                }

                // General error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save
                GGButton(
                    "Save Sleep",
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

    // MARK: - Start Time Section

    private func startTimeSection(viewModel: LogSleepViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(colors.secondary)
                    Text("Fell Asleep")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)
                }

                DatePicker(
                    "Start Time",
                    selection: Binding(
                        get: { viewModel.startTime },
                        set: { viewModel.startTime = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .tint(colors.primary)
            }
        }
    }

    // MARK: - End Time Section

    private func endTimeSection(viewModel: LogSleepViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "sun.horizon.fill")
                        .foregroundStyle(colors.tertiary)
                    Text("Woke Up")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)
                }

                DatePicker(
                    "End Time",
                    selection: Binding(
                        get: { viewModel.endTime },
                        set: { viewModel.endTime = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .tint(colors.primary)
            }
        }
    }

    // MARK: - Duration Section

    private func durationSection(viewModel: LogSleepViewModel) -> some View {
        GGCard(style: .standard) {
            HStack {
                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                    Text("Duration")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)

                    Text(viewModel.isFormValid ? viewModel.durationLabel : "--")
                        .font(.ggTitleLarge)
                        .foregroundStyle(colors.primary)
                }
                Spacer()
                Image(systemName: "clock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(colors.primary.opacity(0.5))
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(viewModel: LogSleepViewModel) -> some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Notes (optional)")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                GGTextEditor(
                    "Any notes about this sleep...",
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

#Preview("Log Sleep") {
    NavigationStack {
        LogSleepView(childId: "test-child")
    }
}
