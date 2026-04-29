import SwiftUI

/// Dedicated view for logging a solid food feeding event.
///
/// Provides food type selection, quantity with unit picker, time picker, and notes.
/// Uses LogFeedingViewModel with solid type pre-selected.
struct LogSolidsView: View {

    // MARK: - Properties

    let childId: String
    let attachmentLoader: CustomItemAttachmentLoader

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

                        solidPickerRow(viewModel: viewModel)
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

                // Reaction
                GGCard(style: .standard) {
                    VStack(alignment: .leading, spacing: GGSpacing.sm) {
                        Text("Reaction (optional)")
                            .font(.ggTitleMedium)
                            .foregroundStyle(colors.onSurface)

                        Text("Did your baby like it?")
                            .font(.ggBodySmall)
                            .foregroundStyle(colors.onSurface.opacity(0.6))

                        reactionPicker(viewModel: viewModel)
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
                            .foregroundStyle(colors.error)
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

    // MARK: - Reaction Picker

    /// Three-segment selector for the caregiver to record how the baby
    /// reacted to this food. Tapping the active option clears it so the
    /// caregiver can leave it unrated.
    private func reactionPicker(viewModel: LogFeedingViewModel) -> some View {
        HStack(spacing: GGSpacing.sm) {
            ForEach(SolidReaction.allCases, id: \.self) { reaction in
                reactionButton(reaction: reaction, viewModel: viewModel)
            }
        }
    }

    private func reactionButton(reaction: SolidReaction, viewModel: LogFeedingViewModel) -> some View {
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

    // MARK: - Picker Row

    private func solidPickerRow(viewModel: LogFeedingViewModel) -> some View {
        NavigationLink {
            CustomItemPickerView(
                childId: childId,
                category: .solidFood,
                attachmentLoader: attachmentLoader
            ) { name, token in
                viewModel.solidType = name
                viewModel.solidAttachmentToken = token
            }
        } label: {
            HStack(spacing: GGSpacing.md) {
                pickerThumbnail(token: viewModel.solidAttachmentToken)

                if viewModel.solidType.isEmpty {
                    Text("Choose a food")
                        .font(.ggBodyLarge)
                        .foregroundStyle(colors.onSurface.opacity(0.5))
                } else {
                    Text(viewModel.solidType)
                        .font(.ggBodyLarge)
                        .foregroundStyle(colors.onSurface)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.3))
            }
            .padding(.horizontal, GGSpacing.md)
            .frame(minHeight: GGSpacing.minimumTouchTarget)
            .background(colors.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.5, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pickerThumbnail(token: String?) -> some View {
        if let token, !token.isEmpty, let image = attachmentLoader.image(for: token) {
            Image(platformImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: "fork.knife")
                .font(.ggBodyLarge)
                .foregroundStyle(colors.onSurface.opacity(0.5))
                .frame(width: 32, height: 32)
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
        LogSolidsView(
            childId: "test-child",
            attachmentLoader: CustomItemAttachmentLoader(dittoManager: DittoManager.shared)
        )
    }
}
