import SwiftUI

/// Form for logging a diaper change event with type toggle, quantity selector,
/// conditional color/consistency pickers (poop only), time picker, and notes.
struct LogDiaperView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: LogDiaperViewModel?

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
        .navigationTitle("Log Diaper")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogDiaperViewModel(
                    childId: childId,
                    diaperRepository: DiaperRepository(dittoManager: DittoManager.shared)
                )
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: LogDiaperViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Type toggle
                typeSection(viewModel: viewModel)

                // Quantity
                quantitySection(viewModel: viewModel)

                // Poop-specific fields
                if viewModel.showPoopFields {
                    poopDetailsSection(viewModel: viewModel)
                }

                // Time
                timeSection(viewModel: viewModel)

                // Notes
                notesSection(viewModel: viewModel)

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save
                GGButton(
                    "Save Diaper Change",
                    variant: .primary,
                    icon: "checkmark.circle",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.save() }
                }
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Type Section

    private func typeSection(viewModel: LogDiaperViewModel) -> some View {
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

    // MARK: - Quantity Section

    private func quantitySection(viewModel: LogDiaperViewModel) -> some View {
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

    // MARK: - Poop Details Section

    private func poopDetailsSection(viewModel: LogDiaperViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Poop Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                // Color picker
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

                // Consistency picker
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

    // MARK: - Color Button

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

    // MARK: - Consistency Button

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

    // MARK: - Time Section

    private func timeSection(viewModel: LogDiaperViewModel) -> some View {
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

    private func notesSection(viewModel: LogDiaperViewModel) -> some View {
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
                .foregroundStyle(GGColors.error)
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

#Preview("Log Diaper") {
    NavigationStack {
        LogDiaperView(childId: "test-child")
    }
}
