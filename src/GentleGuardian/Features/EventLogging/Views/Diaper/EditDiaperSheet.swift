import SwiftUI

/// Sheet for editing or deleting an existing diaper event.
struct EditDiaperSheet: View {

    let event: DiaperEvent
    let diaperRepository: DiaperRepository

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogDiaperViewModel
    @State private var showDeleteConfirmation = false

    init(event: DiaperEvent, diaperRepository: DiaperRepository) {
        self.event = event
        self.diaperRepository = diaperRepository
        _viewModel = State(initialValue: LogDiaperViewModel(
            existingEvent: event,
            diaperRepository: diaperRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        typeSection
                        quantitySection
                        if viewModel.showPoopFields {
                            poopDetailsSection
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
                            isLoading: viewModel.isLoading
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
            .navigationTitle("Edit Diaper")
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
            .alert("Delete this diaper entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the diaper event from the log.")
            }
        }
    }

    // MARK: - Sections

    private var typeSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Type")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Picker("Diaper Type", selection: Binding(
                    get: { viewModel.diaperType },
                    set: { viewModel.diaperType = $0 }
                )) {
                    ForEach(DiaperType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var quantitySection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                Text("Amount")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                Picker("Quantity", selection: Binding(
                    get: { viewModel.quantity },
                    set: { viewModel.quantity = $0 }
                )) {
                    ForEach(DiaperQuantity.allCases, id: \.self) { qty in
                        Text(qty.displayName).tag(qty)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var poopDetailsSection: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Poop Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Color")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: GGSpacing.sm) {
                        ForEach(DiaperColor.allCases, id: \.self) { diaperColor in
                            colorButton(diaperColor, isSelected: viewModel.color == diaperColor) {
                                viewModel.color = diaperColor
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                    Text("Consistency")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: GGSpacing.sm) {
                        ForEach(DiaperConsistency.allCases, id: \.self) { cons in
                            consistencyButton(cons, isSelected: viewModel.consistency == cons) {
                                viewModel.consistency = cons
                            }
                        }
                    }
                }
            }
        }
    }

    private func colorButton(_ color: DiaperColor, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(color.displayName)
                .font(.ggLabelMedium)
                .foregroundStyle(isSelected ? colors.onPrimary : colors.onSurface)
                .frame(maxWidth: .infinity)
                .frame(minHeight: GGSpacing.minimumTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.4, style: .continuous)
                        .fill(isSelected ? colors.primary : colors.surfaceContainerHigh)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.displayName) color")
    }

    private func consistencyButton(_ consistency: DiaperConsistency, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(consistency.displayName)
                .font(.ggLabelMedium)
                .foregroundStyle(isSelected ? colors.onPrimary : colors.onSurface)
                .frame(maxWidth: .infinity)
                .frame(minHeight: GGSpacing.minimumTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.4, style: .continuous)
                        .fill(isSelected ? colors.primary : colors.surfaceContainerHigh)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(consistency.displayName) consistency")
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
