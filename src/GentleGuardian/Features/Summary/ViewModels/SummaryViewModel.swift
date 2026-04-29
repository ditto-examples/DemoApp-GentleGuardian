import Foundation
import Observation

// MARK: - EventPayload

/// Discriminated payload that carries the typed event behind a
/// `TimelineEvent`. Keeping the original event around lets the activity
/// feed route taps to the right Edit sheet with all fields pre-filled.
enum EventPayload: Sendable {
    case feeding(FeedingEvent)
    case diaper(DiaperEvent)
    case health(HealthEvent)
    case activity(ActivityEvent)
    case sleep(SleepEvent)
    case other(OtherEvent)
}

// MARK: - TimelineEvent

/// A unified wrapper representing any event type in the activity feed.
///
/// Allows feeding, diaper, health, and activity events to be merged into
/// a single chronological list for the daily summary view. Carries the
/// original typed event via `payload` so taps can open a category-specific
/// Edit sheet pre-filled with the source event's fields.
struct TimelineEvent: Identifiable, Sendable {
    let payload: EventPayload

    /// Stable identifier — the underlying event's id.
    var id: String {
        switch payload {
        case .feeding(let event): event.id
        case .diaper(let event): event.id
        case .health(let event): event.id
        case .activity(let event): event.id
        case .sleep(let event): event.id
        case .other(let event): event.id
        }
    }

    var timestamp: Date {
        switch payload {
        case .feeding(let event): event.timestamp
        case .diaper(let event): event.timestamp
        case .health(let event): event.timestamp
        case .activity(let event): event.timestamp
        case .sleep(let event): event.timestamp
        case .other(let event): event.timestamp
        }
    }

    var category: EventCategory {
        switch payload {
        case .feeding: .feeding
        case .diaper: .diaper
        case .health: .health
        case .activity: .activity
        case .sleep: .sleep
        case .other: .other
        }
    }

    var iconName: String {
        switch payload {
        case .feeding(let event): event.type.iconName
        case .diaper(let event): event.type.iconName
        case .health(let event): event.type.iconName
        case .activity(let event): event.activityType.iconName
        case .sleep: "moon.fill"
        case .other: "pencil.and.outline"
        }
    }

    var title: String {
        switch payload {
        case .feeding(let event):
            switch event.type {
            case .bottle: "Bottle"
            case .breast: "Breast"
            case .solid: "Solid Food"
            }
        case .diaper(let event): event.type.displayName
        case .health(let event): event.type.displayName
        case .activity(let event): event.activityType.displayName
        case .sleep: "Sleep"
        case .other(let event): event.name
        }
    }

    var detail: String {
        switch payload {
        case .feeding(let event): event.summary
        case .diaper(let event): event.summary
        case .health(let event): event.summary
        case .activity(let event): event.summary
        case .sleep(let event): event.summary
        case .other(let event): event.summary
        }
    }

    /// Display-formatted time string (e.g., "10:30 AM").
    var timeString: String {
        DateService.displayTime(from: timestamp)
    }

    static func from(_ event: FeedingEvent) -> TimelineEvent {
        TimelineEvent(payload: .feeding(event))
    }

    static func from(_ event: DiaperEvent) -> TimelineEvent {
        TimelineEvent(payload: .diaper(event))
    }

    static func from(_ event: HealthEvent) -> TimelineEvent {
        TimelineEvent(payload: .health(event))
    }

    static func from(_ event: ActivityEvent) -> TimelineEvent {
        TimelineEvent(payload: .activity(event))
    }

    static func from(_ event: SleepEvent) -> TimelineEvent {
        TimelineEvent(payload: .sleep(event))
    }

    static func from(_ event: OtherEvent) -> TimelineEvent {
        TimelineEvent(payload: .other(event))
    }
}

// MARK: - SummarySection

/// Top-level segments for the Summary tab.
enum SummarySection: String, CaseIterable, Identifiable, Sendable {
    case activityFeed
    case growth
    case foodRanking

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .activityFeed: "Activity Feed"
        case .growth: "Growth"
        case .foodRanking: "Food Ranking"
        }
    }
}

// MARK: - FoodRankingFilter

/// Filter applied to the Food Ranking list. Backed by overall reaction tilt:
/// `liked` shows foods with more happy than frown ratings; `hated` shows the
/// reverse. `all` shows every rated food.
enum FoodRankingFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case liked
    case hated

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: "All"
        case .liked: "Liked"
        case .hated: "Hated"
        }
    }
}

// MARK: - Repository Protocols for Dependency Injection

/// Protocol defining the read interface for feeding data needed by SummaryViewModel.
@MainActor
protocol SummaryViewFeedingDataSource: AnyObject {
    var events: [FeedingEvent] { get }
    func observeEvents(childId: String, date: String)
    func fetchAllSolidFeedings(childId: String) async throws -> [FeedingEvent]
}

/// Protocol defining the read interface for diaper data needed by SummaryViewModel.
@MainActor
protocol SummaryViewDiaperDataSource: AnyObject {
    var events: [DiaperEvent] { get }
    func observeEvents(childId: String, date: String)
}

/// Protocol defining the read interface for health data needed by SummaryViewModel.
@MainActor
protocol SummaryViewHealthDataSource: AnyObject {
    var events: [HealthEvent] { get }
    func observeEvents(childId: String, date: String)
    func fetchAllGrowth(childId: String) async throws -> [HealthEvent]
}

/// Protocol defining the read interface for activity data needed by SummaryViewModel.
@MainActor
protocol SummaryViewActivityDataSource: AnyObject {
    var events: [ActivityEvent] { get }
    func observeEvents(childId: String, date: String)
}

/// Protocol defining the read interface for sleep data needed by SummaryViewModel.
@MainActor
protocol SummaryViewSleepDataSource: AnyObject {
    var events: [SleepEvent] { get }
    func observeEvents(childId: String, date: String)
}

/// Protocol defining the read interface for other event data needed by SummaryViewModel.
@MainActor
protocol SummaryViewOtherDataSource: AnyObject {
    var events: [OtherEvent] { get }
    func observeEvents(childId: String, date: String)
}

// MARK: - Real Repository Conformances

extension FeedingRepository: SummaryViewFeedingDataSource {}
extension DiaperRepository: SummaryViewDiaperDataSource {}
extension HealthRepository: SummaryViewHealthDataSource {}
extension ActivityRepository: SummaryViewActivityDataSource {}
extension SleepRepository: SummaryViewSleepDataSource {}
extension OtherEventRepository: SummaryViewOtherDataSource {}

// MARK: - SummaryViewModel

/// ViewModel powering the Summary screen.
///
/// Hosts three sub-sections selected via a segmented control:
///   - Activity Feed: chronological list of events for the selected day
///   - Growth: cross-day list of height/weight measurements
///   - Food Ranking: cross-day aggregate of solid feedings with happy/neutral/
///     frown counts and an All/Liked/Hated filter
///
/// The Activity Feed is the only section affected by the date selector.
@Observable
@MainActor
final class SummaryViewModel {

    // MARK: - Dependencies

    private let feedingDataSource: any SummaryViewFeedingDataSource
    private let diaperDataSource: any SummaryViewDiaperDataSource
    private let healthDataSource: any SummaryViewHealthDataSource
    private let activityDataSource: any SummaryViewActivityDataSource
    private let sleepDataSource: any SummaryViewSleepDataSource
    private let otherDataSource: any SummaryViewOtherDataSource
    private let activeChildState: ActiveChildState

    // MARK: - State

    /// The currently selected date for the Activity Feed section.
    var selectedDate: Date = Date() {
        didSet {
            reloadForSelectedDate()
        }
    }

    /// The active section in the Summary tab. Defaults to `.activityFeed`.
    var selectedSection: SummarySection = .activityFeed {
        didSet {
            // Refresh cross-day data the first time a section becomes visible
            // (and on every reselection — these are cheap one-shot queries).
            switch selectedSection {
            case .activityFeed: break
            case .growth: Task { await loadGrowthEvents() }
            case .foodRanking: Task { await loadSolidFeedings() }
            }
        }
    }

    /// Filter applied to the Food Ranking list.
    var foodRankingFilter: FoodRankingFilter = .all

    /// All-time growth events for the active child, newest first.
    private(set) var growthEvents: [HealthEvent] = []

    /// All-time solid feedings used to compute food rankings.
    private(set) var solidFeedings: [FeedingEvent] = []

    /// The child ID currently being observed.
    private(set) var observedChildId: String?

    // MARK: - Initialization

    init(
        feedingRepository: any SummaryViewFeedingDataSource,
        diaperRepository: any SummaryViewDiaperDataSource,
        healthRepository: any SummaryViewHealthDataSource,
        activityRepository: any SummaryViewActivityDataSource,
        sleepRepository: any SummaryViewSleepDataSource,
        otherEventRepository: any SummaryViewOtherDataSource,
        activeChildState: ActiveChildState
    ) {
        self.feedingDataSource = feedingRepository
        self.diaperDataSource = diaperRepository
        self.healthDataSource = healthRepository
        self.activityDataSource = activityRepository
        self.sleepDataSource = sleepRepository
        self.otherDataSource = otherEventRepository
        self.activeChildState = activeChildState
    }

    // MARK: - Computed Properties

    /// Display string for the selected date (e.g., "Apr 15, 2026").
    var selectedDateDisplay: String {
        DateService.displayDate(from: selectedDate)
    }

    /// Whether the selected date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// Whether navigating to the next day is allowed (cannot go beyond today).
    var canGoForward: Bool {
        !isToday
    }

    /// All daily events merged and sorted by timestamp descending.
    var allEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []

        events.append(contentsOf: feedingDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: diaperDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: healthDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: activityDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: sleepDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: otherDataSource.events.map { TimelineEvent.from($0) })

        return events.sorted { $0.timestamp > $1.timestamp }
    }

    /// Aggregated food summaries across all solid feedings for the active
    /// child, filtered to those that have at least one rating.
    var foodSummaries: [FoodReactionSummary] {
        FoodReactionAggregator.summarize(events: solidFeedings)
            .filter { $0.totalRatedCount > 0 }
    }

    /// Food summaries with the active filter applied. Sorted newest-rating-
    /// first by overall score so the strongest tilts surface at the top of
    /// each filter view (`.liked` puts the most-loved first; `.hated` puts the
    /// most-disliked first).
    var filteredFoodSummaries: [FoodReactionSummary] {
        let base: [FoodReactionSummary]
        switch foodRankingFilter {
        case .all:
            base = foodSummaries
        case .liked:
            base = foodSummaries.filter { $0.happyCount > $0.frownCount }
        case .hated:
            base = foodSummaries.filter { $0.frownCount > $0.happyCount }
        }
        return base.sorted { lhs, rhs in
            switch foodRankingFilter {
            case .all, .liked:
                if lhs.score != rhs.score { return lhs.score > rhs.score }
            case .hated:
                if lhs.score != rhs.score { return lhs.score < rhs.score }
            }
            return lhs.foodName.localizedCaseInsensitiveCompare(rhs.foodName) == .orderedAscending
        }
    }

    // MARK: - Actions

    /// Called when the summary view appears. Starts observing data for the active child.
    func onAppear() {
        guard let childId = activeChildState.activeChildId else { return }
        startObserving(childId: childId)
        // Pre-fetch cross-day data so the segmented control feels instant when
        // tapped — these are bounded queries (no observers).
        Task { await loadGrowthEvents() }
        Task { await loadSolidFeedings() }
    }

    /// Called when the active child changes. Restarts observations for the new child.
    func onChildChanged() {
        guard let childId = activeChildState.activeChildId else { return }
        guard childId != observedChildId else { return }
        startObserving(childId: childId)
        Task { await loadGrowthEvents() }
        Task { await loadSolidFeedings() }
    }

    /// Navigates to the previous day.
    func goToPreviousDay() {
        guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        selectedDate = newDate
    }

    /// Navigates to the next day (capped at today).
    func goToNextDay() {
        guard canGoForward else { return }
        guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        selectedDate = newDate
    }

    /// Reloads the all-time growth events list. Exposed so the view can
    /// re-pull after an Edit sheet has saved or deleted a row.
    func loadGrowthEvents() async {
        guard let childId = observedChildId ?? activeChildState.activeChildId else { return }
        do {
            growthEvents = try await healthDataSource.fetchAllGrowth(childId: childId)
        } catch {
            growthEvents = []
        }
    }

    /// Reloads the all-time solid feedings list. Exposed so the view can
    /// re-pull after an Edit sheet has saved or deleted a row.
    func loadSolidFeedings() async {
        guard let childId = observedChildId ?? activeChildState.activeChildId else { return }
        do {
            solidFeedings = try await feedingDataSource.fetchAllSolidFeedings(childId: childId)
        } catch {
            solidFeedings = []
        }
    }

    // MARK: - Private

    private func startObserving(childId: String) {
        observedChildId = childId
        let dateString = DateService.dateString(from: selectedDate)

        feedingDataSource.observeEvents(childId: childId, date: dateString)
        diaperDataSource.observeEvents(childId: childId, date: dateString)
        healthDataSource.observeEvents(childId: childId, date: dateString)
        activityDataSource.observeEvents(childId: childId, date: dateString)
        sleepDataSource.observeEvents(childId: childId, date: dateString)
        otherDataSource.observeEvents(childId: childId, date: dateString)
    }

    private func reloadForSelectedDate() {
        guard let childId = observedChildId else { return }
        let dateString = DateService.dateString(from: selectedDate)

        feedingDataSource.observeEvents(childId: childId, date: dateString)
        diaperDataSource.observeEvents(childId: childId, date: dateString)
        healthDataSource.observeEvents(childId: childId, date: dateString)
        activityDataSource.observeEvents(childId: childId, date: dateString)
        sleepDataSource.observeEvents(childId: childId, date: dateString)
        otherDataSource.observeEvents(childId: childId, date: dateString)
    }
}
