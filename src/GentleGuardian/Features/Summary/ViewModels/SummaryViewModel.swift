import Foundation
import Observation

// MARK: - TimelineEvent

/// A unified wrapper representing any event type in the activity feed.
///
/// Allows feeding, diaper, health, and activity events to be merged into
/// a single chronological list for the daily summary view.
struct TimelineEvent: Identifiable, Sendable {
    let id: String
    let timestamp: Date
    let category: EventCategory
    let iconName: String
    let title: String
    let detail: String

    /// Display-formatted time string (e.g., "10:30 AM").
    var timeString: String {
        DateService.displayTime(from: timestamp)
    }

    /// Creates a TimelineEvent from a FeedingEvent.
    static func from(_ event: FeedingEvent) -> TimelineEvent {
        let title: String
        switch event.type {
        case .bottle:
            title = "Bottle"
        case .breast:
            title = "Breast"
        case .solid:
            title = "Solid Food"
        }
        return TimelineEvent(
            id: event.id,
            timestamp: event.timestamp,
            category: .feeding,
            iconName: event.type.iconName,
            title: title,
            detail: event.summary
        )
    }

    /// Creates a TimelineEvent from a DiaperEvent.
    static func from(_ event: DiaperEvent) -> TimelineEvent {
        TimelineEvent(
            id: event.id,
            timestamp: event.timestamp,
            category: .diaper,
            iconName: event.type.iconName,
            title: event.type.displayName,
            detail: event.summary
        )
    }

    /// Creates a TimelineEvent from a HealthEvent.
    static func from(_ event: HealthEvent) -> TimelineEvent {
        TimelineEvent(
            id: event.id,
            timestamp: event.timestamp,
            category: .health,
            iconName: event.type.iconName,
            title: event.type.displayName,
            detail: event.summary
        )
    }

    /// Creates a TimelineEvent from an ActivityEvent.
    static func from(_ event: ActivityEvent) -> TimelineEvent {
        TimelineEvent(
            id: event.id,
            timestamp: event.timestamp,
            category: .activity,
            iconName: event.activityType.iconName,
            title: event.activityType.displayName,
            detail: event.summary
        )
    }
}

// MARK: - Repository Protocols for Dependency Injection

/// Protocol defining the read interface for feeding data needed by SummaryViewModel.
@MainActor
protocol SummaryViewFeedingDataSource: AnyObject {
    var events: [FeedingEvent] { get }
    func observeEvents(childId: String, date: String)
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
}

/// Protocol defining the read interface for activity data needed by SummaryViewModel.
@MainActor
protocol SummaryViewActivityDataSource: AnyObject {
    var events: [ActivityEvent] { get }
    func observeEvents(childId: String, date: String)
}

// MARK: - Real Repository Conformances

extension FeedingRepository: SummaryViewFeedingDataSource {}
extension DiaperRepository: SummaryViewDiaperDataSource {}
extension HealthRepository: SummaryViewHealthDataSource {}
extension ActivityRepository: SummaryViewActivityDataSource {}

// MARK: - SummaryViewModel

/// ViewModel powering the Daily Summary screen.
///
/// Merges all event types (feeding, diaper, health, activity) into a single
/// chronological timeline for the selected date. Provides stat counts and
/// date navigation.
@Observable
@MainActor
final class SummaryViewModel {

    // MARK: - Dependencies

    private let feedingDataSource: any SummaryViewFeedingDataSource
    private let diaperDataSource: any SummaryViewDiaperDataSource
    private let healthDataSource: any SummaryViewHealthDataSource
    private let activityDataSource: any SummaryViewActivityDataSource
    private let activeChildState: ActiveChildState

    // MARK: - State

    /// The currently selected date for the summary.
    var selectedDate: Date = Date() {
        didSet {
            reloadForSelectedDate()
        }
    }

    /// The child ID currently being observed.
    private(set) var observedChildId: String?

    // MARK: - Initialization

    init(
        feedingRepository: any SummaryViewFeedingDataSource,
        diaperRepository: any SummaryViewDiaperDataSource,
        healthRepository: any SummaryViewHealthDataSource,
        activityRepository: any SummaryViewActivityDataSource,
        activeChildState: ActiveChildState
    ) {
        self.feedingDataSource = feedingRepository
        self.diaperDataSource = diaperRepository
        self.healthDataSource = healthRepository
        self.activityDataSource = activityRepository
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

    /// Total feeding count for the selected day.
    var totalFeedings: Int {
        feedingDataSource.events.count
    }

    /// Total diaper count for the selected day.
    var totalDiapers: Int {
        diaperDataSource.events.count
    }

    /// Total activities for the selected day.
    var totalActivities: Int {
        activityDataSource.events.count
    }

    /// Total health events for the selected day.
    var totalHealthEvents: Int {
        healthDataSource.events.count
    }

    /// All events merged and sorted by timestamp descending.
    var allEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []

        events.append(contentsOf: feedingDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: diaperDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: healthDataSource.events.map { TimelineEvent.from($0) })
        events.append(contentsOf: activityDataSource.events.map { TimelineEvent.from($0) })

        return events.sorted { $0.timestamp > $1.timestamp }
    }

    /// Total number of all events for the selected day.
    var totalEventCount: Int {
        totalFeedings + totalDiapers + totalActivities + totalHealthEvents
    }

    /// A hero stat string for the summary (e.g., total tracked time or event count).
    var heroStatLabel: String {
        let total = totalEventCount
        if total == 0 {
            return "0"
        }
        // Calculate total tracked time from activities with durations
        let totalMinutes = activityDataSource.events.compactMap(\.durationMinutes).reduce(0, +)
        if totalMinutes > 0 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"
        }
        return "\(total)"
    }

    /// Subtitle for the hero stat.
    var heroStatSubtitle: String {
        let totalMinutes = activityDataSource.events.compactMap(\.durationMinutes).reduce(0, +)
        if totalMinutes > 0 {
            return "Total Tracked Time"
        }
        return "Total Events"
    }

    // MARK: - Actions

    /// Called when the summary view appears. Starts observing data for the active child.
    func onAppear() {
        guard let childId = activeChildState.activeChildId else { return }
        startObserving(childId: childId)
    }

    /// Called when the active child changes. Restarts observations for the new child.
    func onChildChanged() {
        guard let childId = activeChildState.activeChildId else { return }
        guard childId != observedChildId else { return }
        startObserving(childId: childId)
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

    // MARK: - Private

    private func startObserving(childId: String) {
        observedChildId = childId
        let dateString = DateService.dateString(from: selectedDate)

        feedingDataSource.observeEvents(childId: childId, date: dateString)
        diaperDataSource.observeEvents(childId: childId, date: dateString)
        healthDataSource.observeEvents(childId: childId, date: dateString)
        activityDataSource.observeEvents(childId: childId, date: dateString)
    }

    private func reloadForSelectedDate() {
        guard let childId = observedChildId else { return }
        let dateString = DateService.dateString(from: selectedDate)

        feedingDataSource.observeEvents(childId: childId, date: dateString)
        diaperDataSource.observeEvents(childId: childId, date: dateString)
        healthDataSource.observeEvents(childId: childId, date: dateString)
        activityDataSource.observeEvents(childId: childId, date: dateString)
    }
}
