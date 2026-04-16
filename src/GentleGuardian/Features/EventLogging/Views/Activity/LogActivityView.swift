import SwiftUI

/// Form for logging an activity event with activity type picker (as GGActivityBubbles),
/// optional duration, description, and time picker.
struct LogActivityView: View {

    // MARK: - Properties

    let childId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isNightMode) private var isNightMode

    // MARK: - State

    @State private var viewModel: LogActivityViewModel?

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
        .navigationTitle("Log Activity")
        .inlineNavigationBarTitle()
        .onAppear {
            if viewModel == nil {
                viewModel = LogActivityViewModel(
                    childId: childId,
                    activityRepository: ActivityRepository(dittoManager: DittoManager.shared)
                )
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: LogActivityViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Activity type grid
                activityTypeSection(viewModel: viewModel)

                // Duration (optional)
                if viewModel.activityType.hasDuration {
                    durationSection(viewModel: viewModel)
                }

                // Description
                descriptionSection(viewModel: viewModel)

                // Time
                timeSection(viewModel: viewModel)

                // Error
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Save
                GGButton(
                    "Save Activity",
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

    // MARK: - Activity Type Section

    private func activityTypeSection(viewModel: LogActivityViewModel) -> some View {
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

    // MARK: - Activity Bubble

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
                    .fill(isSelected ? colors.primary : (isNightMode ? GGColors.secondaryContainerDim.opacity(0.5) : GGColors.secondaryFixed))
            )
        }
        .buttonStyle(GGBubbleSelectionStyle())
        .accessibilityLabel("Select \(type.displayName)")
    }

    // MARK: - Duration Section

    private func durationSection(viewModel: LogActivityViewModel) -> some View {
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

    // MARK: - Description Section

    private func descriptionSection(viewModel: LogActivityViewModel) -> some View {
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

    // MARK: - Time Section

    private func timeSection(viewModel: LogActivityViewModel) -> some View {
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

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: GGSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GGColors.error)
            Text(message).font(.ggBodyMedium).foregroundStyle(colors.onSurface)
        }
        .padding(GGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}

// MARK: - Button Style

private struct GGBubbleSelectionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Log Activity") {
    NavigationStack {
        LogActivityView(childId: "test-child")
    }
}
