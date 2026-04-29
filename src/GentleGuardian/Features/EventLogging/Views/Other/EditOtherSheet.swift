import SwiftUI

/// Sheet for editing or deleting an existing "other" event.
struct EditOtherSheet: View {

    let event: OtherEvent
    let otherEventRepository: OtherEventRepository

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogOtherViewModel
    @State private var showDeleteConfirmation = false

    init(event: OtherEvent, otherEventRepository: OtherEventRepository) {
        self.event = event
        self.otherEventRepository = otherEventRepository
        _viewModel = State(initialValue: LogOtherViewModel(
            existingEvent: event,
            otherEventRepository: otherEventRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        nameSection
                        durationSection
                        descriptionSection
                        timeSection

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
            .navigationTitle("Edit Event")
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
            .alert("Delete this entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the event from the log.")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Activity Name")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "What are you tracking?",
                    text: Binding(
                        get: { viewModel.name },
                        set: { viewModel.name = $0 }
                    ),
                    icon: "pencil.and.outline"
                )
            }
        }
    }

    private var durationSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Duration (minutes, optional)")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                GGTextField(
                    "Minutes",
                    text: Binding(
                        get: { viewModel.durationMinutes },
                        set: { viewModel.durationMinutes = $0 }
                    ),
                    icon: "clock",
                    keyboardType: .numberPad
                )
            }
        }
    }

    private var descriptionSection: some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Description (optional)")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                GGTextEditor(
                    "Any details about this event...",
                    text: Binding(
                        get: { viewModel.eventDescription },
                        set: { viewModel.eventDescription = $0 }
                    ),
                    minHeight: 80
                )
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
