import SwiftUI

/// Sheet for editing or deleting an existing feeding event.
/// Routes to the appropriate field set (bottle / breast / solid) based on `event.type`.
struct EditFeedingSheet: View {

    let event: FeedingEvent
    let feedingRepository: FeedingRepository
    let attachmentLoader: CustomItemAttachmentLoader

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogFeedingViewModel
    @State private var showDeleteConfirmation = false

    init(event: FeedingEvent, feedingRepository: FeedingRepository, attachmentLoader: CustomItemAttachmentLoader) {
        self.event = event
        self.feedingRepository = feedingRepository
        self.attachmentLoader = attachmentLoader
        _viewModel = State(initialValue: LogFeedingViewModel(
            existingEvent: event,
            feedingRepository: feedingRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        switch viewModel.feedingType {
                        case .bottle:
                            bottleFields
                        case .breast:
                            breastFields
                        case .solid:
                            solidFields
                            reactionSection
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
            .navigationTitle(editTitle)
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
            .alert("Delete this feeding entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the feeding event from the log.")
            }
        }
    }

    private var editTitle: String {
        switch viewModel.feedingType {
        case .bottle: return "Edit Bottle"
        case .breast: return "Edit Breastfeeding"
        case .solid: return "Edit Solid Food"
        }
    }

    // MARK: - Bottle Fields

    private var bottleFields: some View {
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

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Formula Type (optional)")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.6))

                    GGTextField(
                        "Formula name",
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

    private var breastFields: some View {
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

    private var solidFields: some View {
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
                        "Food name",
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

    // MARK: - Reaction Section

    private var reactionSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Reaction (optional)")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Text("Did your baby like it?")
                    .font(.ggBodySmall)
                    .foregroundStyle(colors.onSurface.opacity(0.6))

                HStack(spacing: GGSpacing.sm) {
                    ForEach(SolidReaction.allCases, id: \.self) { reaction in
                        reactionButton(reaction: reaction)
                    }
                }
            }
        }
    }

    private func reactionButton(reaction: SolidReaction) -> some View {
        let isSelected = viewModel.solidReaction == reaction
        return Button {
            viewModel.solidReaction = isSelected ? nil : reaction
        } label: {
            VStack(spacing: GGSpacing.xs) {
                Text(reaction.emoji)
                    .font(.system(size: 32))
                Text(reaction.displayName)
                    .font(.ggLabelSmall)
                    .foregroundStyle(colors.onSurface.opacity(isSelected ? 1.0 : 0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GGSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous)
                    .fill(isSelected ? reaction.tintColor.opacity(0.15) : colors.surfaceContainerHigh)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous)
                    .stroke(isSelected ? reaction.tintColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reaction.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Time / Notes / Error

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
