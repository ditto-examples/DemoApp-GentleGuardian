import SwiftUI

/// Main summary tab view displaying a daily overview of all events.
///
/// Structure:
/// 1. "Daily Summary" title
/// 2. Hero stat display (total tracked time or event count)
/// 3. Stats row (total feedings, diapers, activities)
/// 4. Date navigation (previous/next day)
/// 5. Activity feed list (chronological events)
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
                heroSection
                statsSection
                dateNavigationSection
                activityFeedSection
            }
            .padding(.bottom, GGSpacing.xxl)
        }
        .background(GGColors.surface)
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

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: GGSpacing.sm) {
            GGCard(style: .hero) {
                VStack(spacing: GGSpacing.sm) {
                    Text(viewModel.heroStatSubtitle.uppercased())
                        .font(.ggLabelSmall)
                        .foregroundStyle(heroTextColor.opacity(0.7))
                        .tracking(1.2)

                    Text(viewModel.heroStatLabel)
                        .font(.ggDisplayMedium)
                        .foregroundStyle(heroTextColor)

                    Text(viewModel.heroStatSubtitle)
                        .font(.ggBodyMedium)
                        .foregroundStyle(heroTextColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, GGSpacing.md)
        .pageHorizontalPadding()
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
                .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)

            Spacer()

            HStack(spacing: GGSpacing.md) {
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colorScheme == .dark ? GGColors.primaryDark : GGColors.primary)
                        .frame(minWidth: GGSpacing.minimumTouchTarget, minHeight: GGSpacing.minimumTouchTarget)
                }

                Text(viewModel.isToday ? "Today" : viewModel.selectedDateDisplay)
                    .font(.ggLabelLarge)
                    .foregroundStyle(colorScheme == .dark ? GGColors.onSurfaceDark : GGColors.onSurface)

                Button {
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.ggLabelLarge)
                        .foregroundStyle(
                            viewModel.canGoForward
                                ? (colorScheme == .dark ? GGColors.primaryDark : GGColors.primary)
                                : GGColors.onSurfaceVariant.opacity(0.3)
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

    private var heroTextColor: Color {
        colorScheme == .dark ? GGColors.onPrimaryDark : GGColors.onPrimary
    }
}
