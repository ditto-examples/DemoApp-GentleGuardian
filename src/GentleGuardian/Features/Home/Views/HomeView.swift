import SwiftUI

/// Main home tab view displaying the dashboard for the active child.
///
/// Structure:
/// 1. Greeting header with child name
/// 2. Last Feeding hero card with gradient
/// 3. Status row (sleep, diaper, feedings)
/// 4. Quick Log grid for fast event entry
struct HomeView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState

    // MARK: - State

    @State private var viewModel: HomeViewModel

    // MARK: - Initialization

    init(
        feedingRepository: FeedingRepository,
        diaperRepository: DiaperRepository,
        activityRepository: ActivityRepository,
        healthRepository: HealthRepository,
        activeChildState: ActiveChildState
    ) {
        _viewModel = State(initialValue: HomeViewModel(
            feedingRepository: feedingRepository,
            diaperRepository: diaperRepository,
            activityRepository: activityRepository,
            healthRepository: healthRepository,
            activeChildState: activeChildState
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
                greetingHeader
                lastFeedingSection
                statusSection
                quickLogSection
            }
            .padding(.bottom, GGSpacing.xxl)
        }
        .background(GGColors.surface)
        .navigationTitle("Gentle Guardian")
        .inlineNavigationBarTitle()
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
        .sheet(item: $viewModel.selectedEventCategory) { category in
            eventLoggingSheet(for: category)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: GGSpacing.xs) {
            Text("\(viewModel.greeting)")
                .font(.ggHeadlineLarge)
                .foregroundStyle(GGColors.onSurface)

            Text(viewModel.greetingSubtitle)
                .font(.ggBodyMedium)
                .foregroundStyle(GGColors.onSurfaceVariant)
        }
        .padding(.top, GGSpacing.md)
        .asymmetricHorizontalPadding()
    }

    // MARK: - Last Feeding Section

    private var lastFeedingSection: some View {
        LastFeedingCard(
            typeLabel: viewModel.lastFeedingTypeLabel,
            timeString: viewModel.lastFeedingTimeString,
            relativeTime: viewModel.lastFeedingRelativeTime,
            detail: viewModel.lastFeedingDetail,
            hasData: viewModel.lastFeeding != nil
        )
        .pageHorizontalPadding()
    }

    // MARK: - Status Section

    private var statusSection: some View {
        StatusRow(
            sleepLabel: viewModel.sleepDurationLabel,
            diaperLabel: viewModel.diaperStatusLabel,
            diaperRelativeTime: viewModel.diaperRelativeTime,
            feedingCount: viewModel.todayFeedingCount
        )
        .pageHorizontalPadding()
    }

    // MARK: - Quick Log Section

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.md) {
            Text("Quick Log")
                .font(.ggTitleLarge)
                .foregroundStyle(GGColors.onSurface)
                .asymmetricHorizontalPadding()

            QuickLogGrid { category in
                viewModel.quickLogTapped(category)
            }
            .pageHorizontalPadding()
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private func eventLoggingSheet(for category: EventCategory) -> some View {
        if let childId = activeChildState.activeChildId {
            LogEventSheet(category: category, childId: childId)
        }
    }
}

// MARK: - EventCategory Identifiable Conformance

extension EventCategory: Identifiable {
    var id: String { rawValue }
}
