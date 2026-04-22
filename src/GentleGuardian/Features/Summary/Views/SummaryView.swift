import SwiftUI

/// Main summary tab view displaying a daily overview of all events.
///
/// Structure:
/// 1. "Daily Summary" title
/// 2. Stats row (total feedings, diapers, activities)
/// 3. Date navigation (previous/next day)
/// 4. Activity feed list (chronological events)
struct SummaryView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: SummaryViewModel

    // MARK: - Initialization

    init(
        feedingRepository: FeedingRepository,
        diaperRepository: DiaperRepository,
        healthRepository: HealthRepository,
        activityRepository: ActivityRepository,
        sleepRepository: SleepRepository,
        otherEventRepository: OtherEventRepository,
        activeChildState: ActiveChildState
    ) {
        _viewModel = State(initialValue: SummaryViewModel(
            feedingRepository: feedingRepository,
            diaperRepository: diaperRepository,
            healthRepository: healthRepository,
            activityRepository: activityRepository,
            sleepRepository: sleepRepository,
            otherEventRepository: otherEventRepository,
            activeChildState: activeChildState
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
                statsSection
                dateNavigationSection
                activityFeedSection
            }
            .padding(.bottom, GGSpacing.xxl)
        }
        .background(colors.surface)
        .navigationTitle("Daily Summary")
        .toolbar {
            ToolbarItem(placement: .trailingToolbar) {
                ChildSelectorMenu()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: activeChildState.activeChildId) {
            viewModel.onChildChanged()
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        SummaryStatsRow(
            totalFeedings: viewModel.totalFeedings,
            totalDiapers: viewModel.totalDiapers,
            totalActivitiesAndHealth: viewModel.totalActivities + viewModel.totalHealthEvents
        )
        .pageHorizontalPadding()
    }

    // MARK: - Date Navigation

    private var dateNavigationSection: some View {
        HStack {
            Text("Activity Feed")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)

            Spacer()

            HStack(spacing: GGSpacing.md) {
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.primary)
                        .frame(minWidth: GGSpacing.minimumTouchTarget, minHeight: GGSpacing.minimumTouchTarget)
                }

                Text(viewModel.isToday ? "Today" : viewModel.selectedDateDisplay)
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Button {
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.ggLabelLarge)
                        .foregroundStyle(
                            viewModel.canGoForward
                                ? colors.primary
                                : colors.onSurfaceVariant.opacity(0.3)
                        )
                        .frame(minWidth: GGSpacing.minimumTouchTarget, minHeight: GGSpacing.minimumTouchTarget)
                }
                .disabled(!viewModel.canGoForward)
            }
        }
        .asymmetricHorizontalPadding()
    }

    // MARK: - Activity Feed

    private var activityFeedSection: some View {
        ActivityFeedList(events: viewModel.allEvents)
            .pageHorizontalPadding()
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
