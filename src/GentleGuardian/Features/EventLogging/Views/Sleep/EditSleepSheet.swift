import SwiftUI

/// Sheet for editing or deleting an existing sleep event.
struct EditSleepSheet: View {

    let event: SleepEvent
    let sleepRepository: SleepRepository

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogSleepViewModel
    @State private var showDeleteConfirmation = false

    init(event: SleepEvent, sleepRepository: SleepRepository) {
        self.event = event
        self.sleepRepository = sleepRepository
        _viewModel = State(initialValue: LogSleepViewModel(
            existingEvent: event,
            sleepRepository: sleepRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        startTimeSection
                        endTimeSection
                        durationSection
                        notesSection

                        if let message = viewModel.timeValidationMessage {
                            errorBanner(message: message)
                        }
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
            .navigationTitle("Edit Sleep")
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
            .alert("Delete this sleep entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the sleep event from the log.")
            }
        }
    }

    // MARK: - Sections

    private var startTimeSection: some View {
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

    private var endTimeSection: some View {
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

    private var durationSection: some View {
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

    private var notesSection: some View {
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
