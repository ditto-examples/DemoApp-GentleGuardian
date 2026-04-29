import SwiftUI

/// Main summary tab view.
///
/// A segmented control switches between three sub-views:
///   - **Activity Feed** (default): chronological list of all events for the
///     selected day, with date navigation. Tapping a row opens an Edit sheet.
///   - **Growth**: cross-day list of height/weight measurements, newest first.
///     Tapping a row opens the Edit Health sheet.
///   - **Food Ranking**: cross-day aggregate of solid feedings showing happy /
///     neutral / frown counts, filterable by All / Liked / Hated.
struct SummaryView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Dependencies

    private let feedingRepository: FeedingRepository
    private let diaperRepository: DiaperRepository
    private let healthRepository: HealthRepository
    private let activityRepository: ActivityRepository
    private let sleepRepository: SleepRepository
    private let otherEventRepository: OtherEventRepository
    private let attachmentLoader: CustomItemAttachmentLoader

    // MARK: - State

    @State private var viewModel: SummaryViewModel
    @State private var selectedEvent: TimelineEvent?
    @State private var selectedGrowthEvent: HealthEvent?

    // MARK: - Initialization

    init(
        feedingRepository: FeedingRepository,
        diaperRepository: DiaperRepository,
        healthRepository: HealthRepository,
        activityRepository: ActivityRepository,
        sleepRepository: SleepRepository,
        otherEventRepository: OtherEventRepository,
        activeChildState: ActiveChildState,
        attachmentLoader: CustomItemAttachmentLoader
    ) {
        self.feedingRepository = feedingRepository
        self.diaperRepository = diaperRepository
        self.healthRepository = healthRepository
        self.activityRepository = activityRepository
        self.sleepRepository = sleepRepository
        self.otherEventRepository = otherEventRepository
        self.attachmentLoader = attachmentLoader
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
                sectionPicker
                sectionContent
            }
            .padding(.bottom, GGSpacing.xxl)
        }
        .background(colors.surface)
        .navigationTitle("Summary")
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
        .sheet(item: $selectedEvent, onDismiss: {
            // Refresh cross-day data so any edits to feeding/health rows are
            // reflected in the Growth and Food Ranking sections.
            Task {
                await viewModel.loadGrowthEvents()
                await viewModel.loadSolidFeedings()
            }
        }) { event in
            editSheet(for: event)
        }
        .sheet(item: $selectedGrowthEvent, onDismiss: {
            Task { await viewModel.loadGrowthEvents() }
        }) { event in
            EditHealthSheet(
                event: event,
                healthRepository: healthRepository,
                customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared)
            )
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack {
            Spacer(minLength: 0)
            Picker("Section", selection: $viewModel.selectedSection) {
                ForEach(SummarySection.allCases) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .accessibilityIdentifier("summary-section-picker")
            Spacer(minLength: 0)
        }
        .pageHorizontalPadding()
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch viewModel.selectedSection {
        case .activityFeed:
            activityFeedSection
        case .growth:
            growthSection
        case .foodRanking:
            foodRankingSection
        }
    }

    // MARK: - Activity Feed Section

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
            dateNavigationRow

            ActivityFeedList(events: viewModel.allEvents) { event in
                selectedEvent = event
            }
            .pageHorizontalPadding()
        }
    }

    private var dateNavigationRow: some View {
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

    // MARK: - Growth Section

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
            Text("Growth")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)
                .asymmetricHorizontalPadding()

            GrowthList(events: viewModel.growthEvents) { event in
                selectedGrowthEvent = event
            }
            .pageHorizontalPadding()
        }
    }

    // MARK: - Food Ranking Section

    private var foodRankingSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
            Text("Food Ranking")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)
                .asymmetricHorizontalPadding()

            FoodRankingList(
                filter: $viewModel.foodRankingFilter,
                summaries: viewModel.filteredFoodSummaries
            )
            .pageHorizontalPadding()
        }
    }

    // MARK: - Edit Sheet Routing

    @ViewBuilder
    private func editSheet(for event: TimelineEvent) -> some View {
        switch event.payload {
        case .feeding(let feedingEvent):
            EditFeedingSheet(
                event: feedingEvent,
                feedingRepository: feedingRepository,
                attachmentLoader: attachmentLoader
            )
        case .diaper(let diaperEvent):
            EditDiaperSheet(
                event: diaperEvent,
                diaperRepository: diaperRepository
            )
        case .health(let healthEvent):
            EditHealthSheet(
                event: healthEvent,
                healthRepository: healthRepository,
                customItemRepository: CustomItemRepository(dittoManager: DittoManager.shared)
            )
        case .activity(let activityEvent):
            EditActivitySheet(
                event: activityEvent,
                activityRepository: activityRepository
            )
        case .sleep(let sleepEvent):
            EditSleepSheet(
                event: sleepEvent,
                sleepRepository: sleepRepository
            )
        case .other(let otherEvent):
            EditOtherSheet(
                event: otherEvent,
                otherEventRepository: otherEventRepository
            )
        }
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
