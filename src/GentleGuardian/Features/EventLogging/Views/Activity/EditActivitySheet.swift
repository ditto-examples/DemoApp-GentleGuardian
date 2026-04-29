import SwiftUI

/// Sheet for editing or deleting an existing activity event.
struct EditActivitySheet: View {

    let event: ActivityEvent
    let activityRepository: ActivityRepository

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogActivityViewModel
    @State private var showDeleteConfirmation = false

    init(event: ActivityEvent, activityRepository: ActivityRepository) {
        self.event = event
        self.activityRepository = activityRepository
        _viewModel = State(initialValue: LogActivityViewModel(
            existingEvent: event,
            activityRepository: activityRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        activityTypeSection
                        if viewModel.activityType.hasDuration {
                            durationSection
                        }
                        descriptionSection
                        timeSection

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
            .navigationTitle("Edit Activity")
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
            .alert("Delete this activity?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the activity from the log.")
            }
        }
    }

    // MARK: - Sections

    private var activityTypeSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text("Activity Type")
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurface)
                .asymmetricHorizontalPadding()

            let columns = [
                GridItem(.flexible(), spacing: GGSpacing.sm),
                GridItem(.flexible(), spacing: GGSpacing.sm),
                GridItem(.flexible(), spacing: GGSpacing.sm),
                GridItem(.flexible(), spacing: GGSpacing.sm)
            ]

            LazyVGrid(columns: columns, spacing: GGSpacing.sm) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    activityBubble(type, isSelected: viewModel.activityType == type) {
                        viewModel.activityType = type
                    }
                }
            }
        }
    }

    private func activityBubble(_ type: ActivityType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: GGSpacing.sm) {
                Image(systemName: type.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? colors.onPrimary : colors.primary)

                Text(type.displayName)
                    .font(.ggLabelMedium)
                    .foregroundStyle(isSelected ? colors.onPrimary : colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: GGSpacing.activityBubbleHeight + GGSpacing.lg)
            .padding(.horizontal, GGSpacing.sm)
            .padding(.vertical, GGSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.75, style: .continuous)
                    .fill(isSelected ? colors.primary : colors.secondaryContainer.opacity(colorScheme == .dark ? 0.5 : 1.0))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(type.displayName)")
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
                    "What did you do?",
                    text: Binding(
                        get: { viewModel.activityDescription },
                        set: { viewModel.activityDescription = $0 }
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
