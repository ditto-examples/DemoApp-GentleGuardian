import Foundation
import Observation

// MARK: - Repository Protocols for Dependency Injection

/// Protocol defining the read interface for feeding data needed by HomeViewModel.
@MainActor
protocol HomeViewFeedingDataSource: AnyObject {
    var events: [FeedingEvent] { get }
    var latestEvent: FeedingEvent? { get }
    func observeEvents(childId: String, date: String)
    func observeLatestFeeding(childId: String)
}

/// Protocol defining the read interface for diaper data needed by HomeViewModel.
@MainActor
protocol HomeViewDiaperDataSource: AnyObject {
    var events: [DiaperEvent] { get }
    var latestEvent: DiaperEvent? { get }
    func observeEvents(childId: String, date: String)
    func observeLatestDiaper(childId: String)
}

/// Protocol defining the read interface for activity data needed by HomeViewModel.
@MainActor
protocol HomeViewActivityDataSource: AnyObject {
    var events: [ActivityEvent] { get }
    func observeEvents(childId: String, date: String)
}

/// Protocol defining the read interface for health data needed by HomeViewModel.
@MainActor
protocol HomeViewHealthDataSource: AnyObject {
    var events: [HealthEvent] { get }
    func observeEvents(childId: String, date: String)
}

// MARK: - Real Repository Conformances

extension FeedingRepository: HomeViewFeedingDataSource {}
extension DiaperRepository: HomeViewDiaperDataSource {}
extension ActivityRepository: HomeViewActivityDataSource {}
extension HealthRepository: HomeViewHealthDataSource {}

// MARK: - HomeViewModel

/// ViewModel powering the Home dashboard screen.
///
/// Observes the latest feeding, diaper, and today's event counts for the active child.
/// Drives the greeting header, hero card, status row, and quick-log grid.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Dependencies

    private let feedingDataSource: any HomeViewFeedingDataSource
    private let diaperDataSource: any HomeViewDiaperDataSource
    private let activityDataSource: any HomeViewActivityDataSource
    private let healthDataSource: any HomeViewHealthDataSource
    private let activeChildState: ActiveChildState

    // MARK: - State

    /// The event category selected for quick-log sheet presentation.
    var selectedEventCategory: EventCategory?

    /// Today's date string in "YYYY-MM-DD" format, updated on appear.
    private(set) var todayString: String = DateService.todayString()

    /// The child ID currently being observed.
    private(set) var observedChildId: String?

    // MARK: - Initialization

    init(
        feedingRepository: any HomeViewFeedingDataSource,
        diaperRepository: any HomeViewDiaperDataSource,
        activityRepository: any HomeViewActivityDataSource,
        healthRepository: any HomeViewHealthDataSource,
        activeChildState: ActiveChildState
    ) {
        self.feedingDataSource = feedingRepository
        self.diaperDataSource = diaperRepository
        self.activityDataSource = activityRepository
        self.healthDataSource = healthRepository
        self.activeChildState = activeChildState
    }

    // MARK: - Computed Properties

    /// Time-of-day greeting string (e.g., "Good morning").
    var greeting: String {
        DateService.greetingForTimeOfDay()
    }

    /// The active child's first name, or nil if no child is selected.
    var childFirstName: String? {
        activeChildState.activeChild?.firstName
    }

    /// Subtitle text below the greeting.
    var greetingSubtitle: String {
        if let child = activeChildState.activeChild {
            let age = child.ageString
            return "\(child.firstName) is \(age) old. \(DateService.subtitleMessageForTimeOfDay())"
        }
        return "Welcome to Gentle Guardian"
    }

    /// The most recent feeding event for the active child.
    var lastFeeding: FeedingEvent? {
        feedingDataSource.latestEvent
    }

    /// Human-readable description of the last feeding type.
    var lastFeedingTypeLabel: String {
        guard let feeding = lastFeeding else { return "No feedings yet" }
        switch feeding.type {
        case .bottle:
            if let formula = feeding.formulaType, !formula.isEmpty {
                return "\(formula) Bottle"
            }
            return "Bottle"
        case .breast:
            if let side = feeding.breastSide {
                return "Breast (\(side.displayName))"
            }
            return "Breast"
        case .solid:
            if let solidType = feeding.solidType, !solidType.isEmpty {
                return solidType
            }
            return "Solid Food"
        }
    }

    /// Time string for the last feeding (e.g., "7:15 AM").
    var lastFeedingTimeString: String {
        guard let feeding = lastFeeding else { return "--" }
        return DateService.displayTime(from: feeding.timestamp)
    }

    /// Relative time since last feeding (e.g., "3h 12m ago").
    var lastFeedingRelativeTime: String {
        guard let feeding = lastFeeding else { return "" }
        return DateService.relativeTimeString(from: feeding.timestamp)
    }

    /// Detail string for the last feeding (quantity, duration, etc.).
    var lastFeedingDetail: String {
        guard let feeding = lastFeeding else { return "" }
        return feeding.summary
    }

    /// The most recent diaper event for the active child.
    var lastDiaper: DiaperEvent? {
        diaperDataSource.latestEvent
    }

    /// Diaper status label ("Clean" or type description).
    var diaperStatusLabel: String {
        guard lastDiaper != nil else { return "No data" }
        return "Clean"
    }

    /// Relative time since the last diaper change.
    var diaperRelativeTime: String {
        guard let diaper = lastDiaper else { return "" }
        return DateService.relativeTimeString(from: diaper.timestamp)
    }

    /// Total feeding events for today.
    var todayFeedingCount: Int {
        feedingDataSource.events.count
    }

    /// Total diaper events for today.
    var todayDiaperCount: Int {
        diaperDataSource.events.count
    }

    /// Placeholder sleep duration string.
    var sleepDurationLabel: String {
        "9h 12m"
    }

    /// Total activities for today.
    var todayActivityCount: Int {
        activityDataSource.events.count
    }

    /// Total health events for today.
    var todayHealthCount: Int {
        healthDataSource.events.count
    }

    // MARK: - Actions

    /// Called when the home view appears. Starts observing data for the active child.
    func onAppear() {
        todayString = DateService.todayString()
        guard let childId = activeChildState.activeChildId else { return }
        startObserving(childId: childId)
    }

    /// Called when the active child changes. Restarts observations for the new child.
    func onChildChanged() {
        guard let childId = activeChildState.activeChildId else { return }
        guard childId != observedChildId else { return }
        startObserving(childId: childId)
    }

    /// Handles tapping a quick-log activity bubble.
    func quickLogTapped(_ category: EventCategory) {
        selectedEventCategory = category
    }

    // MARK: - Private

    private func startObserving(childId: String) {
        observedChildId = childId
        todayString = DateService.todayString()

        // Observe today's events for counts
        feedingDataSource.observeEvents(childId: childId, date: todayString)
        diaperDataSource.observeEvents(childId: childId, date: todayString)
        activityDataSource.observeEvents(childId: childId, date: todayString)
        healthDataSource.observeEvents(childId: childId, date: todayString)

        // Observe latest events (across all dates) for hero card
        feedingDataSource.observeLatestFeeding(childId: childId)
        diaperDataSource.observeLatestDiaper(childId: childId)
    }
}
