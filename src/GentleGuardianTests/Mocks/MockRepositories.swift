import Foundation
@testable import GentleGuardian

// MARK: - MockChildRepository

/// Mock ChildRepository for ViewModel tests.
///
/// Provides canned data and tracks method calls without requiring a real DittoManaging instance.
@Observable
@MainActor
final class MockChildRepository {

    // MARK: - Published State (mirrors ChildRepository)

    var children: [Child] = []
    var observedChild: Child?

    // MARK: - Call Tracking

    var observeChildrenCalled = false
    var observeChildIdCalled: String?
    var findBySyncCodeCalled: String?
    var insertedChildren: [Child] = []
    var updatedChildren: [Child] = []
    var softDeletedChildIds: [String] = []
    var allChildIdsCalled = false

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")
    var mockSyncCodeResult: Child?
    var mockChildIds: [String] = []

    // MARK: - Methods

    func observeChildren() {
        observeChildrenCalled = true
    }

    func observeChild(id: String) {
        observeChildIdCalled = id
        observedChild = children.first { $0.id == id }
    }

    func findBySyncCode(syncCode: String) async -> Child? {
        findBySyncCodeCalled = syncCode
        return mockSyncCodeResult
    }

    func allChildIds() async throws -> [String] {
        allChildIdsCalled = true
        if shouldThrow { throw mockError }
        return mockChildIds
    }

    func insert(child: Child) async throws {
        if shouldThrow { throw mockError }
        insertedChildren.append(child)
        children.append(child)
    }

    func update(child: Child) async throws {
        if shouldThrow { throw mockError }
        updatedChildren.append(child)
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
        }
    }

    func softDelete(childId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedChildIds.append(childId)
        children.removeAll { $0.id == childId }
    }

    func reset() {
        children.removeAll()
        observedChild = nil
        observeChildrenCalled = false
        observeChildIdCalled = nil
        findBySyncCodeCalled = nil
        insertedChildren.removeAll()
        updatedChildren.removeAll()
        softDeletedChildIds.removeAll()
        allChildIdsCalled = false
        shouldThrow = false
        mockSyncCodeResult = nil
        mockChildIds.removeAll()
    }
}

// MARK: - MockFeedingRepository

/// Mock FeedingRepository for ViewModel tests.
@Observable
@MainActor
final class MockFeedingRepository {

    // MARK: - Published State

    var events: [FeedingEvent] = []
    var latestEvent: FeedingEvent?

    // MARK: - Call Tracking

    var observeEventsArgs: (childId: String, date: String)?
    var observeLatestArgs: String?
    var insertedEvents: [FeedingEvent] = []
    var updatedEvents: [FeedingEvent] = []
    var softDeletedEventIds: [String] = []
    var countForDayArgs: (childId: String, date: String)?

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")
    var mockCount = 0

    // MARK: - Methods

    func observeEvents(childId: String, date: String) {
        observeEventsArgs = (childId: childId, date: date)
    }

    func observeLatestFeeding(childId: String) {
        observeLatestArgs = childId
    }

    func insert(event: FeedingEvent) async throws {
        if shouldThrow { throw mockError }
        insertedEvents.append(event)
        events.append(event)
        latestEvent = event
    }

    func update(event: FeedingEvent) async throws {
        if shouldThrow { throw mockError }
        updatedEvents.append(event)
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }

    func softDelete(eventId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedEventIds.append(eventId)
        events.removeAll { $0.id == eventId }
    }

    func countForDay(childId: String, date: String) async throws -> Int {
        countForDayArgs = (childId: childId, date: date)
        if shouldThrow { throw mockError }
        return mockCount
    }

    func reset() {
        events.removeAll()
        latestEvent = nil
        observeEventsArgs = nil
        observeLatestArgs = nil
        insertedEvents.removeAll()
        updatedEvents.removeAll()
        softDeletedEventIds.removeAll()
        countForDayArgs = nil
        shouldThrow = false
        mockCount = 0
    }
}

// MARK: - MockDiaperRepository

/// Mock DiaperRepository for ViewModel tests.
@Observable
@MainActor
final class MockDiaperRepository {

    // MARK: - Published State

    var events: [DiaperEvent] = []
    var latestEvent: DiaperEvent?

    // MARK: - Call Tracking

    var observeEventsArgs: (childId: String, date: String)?
    var observeLatestArgs: String?
    var insertedEvents: [DiaperEvent] = []
    var updatedEvents: [DiaperEvent] = []
    var softDeletedEventIds: [String] = []
    var countForDayArgs: (childId: String, date: String)?

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")
    var mockCount = 0

    // MARK: - Methods

    func observeEvents(childId: String, date: String) {
        observeEventsArgs = (childId: childId, date: date)
    }

    func observeLatestDiaper(childId: String) {
        observeLatestArgs = childId
    }

    func insert(event: DiaperEvent) async throws {
        if shouldThrow { throw mockError }
        insertedEvents.append(event)
        events.append(event)
        latestEvent = event
    }

    func update(event: DiaperEvent) async throws {
        if shouldThrow { throw mockError }
        updatedEvents.append(event)
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }

    func softDelete(eventId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedEventIds.append(eventId)
        events.removeAll { $0.id == eventId }
    }

    func countForDay(childId: String, date: String) async throws -> Int {
        countForDayArgs = (childId: childId, date: date)
        if shouldThrow { throw mockError }
        return mockCount
    }

    func reset() {
        events.removeAll()
        latestEvent = nil
        observeEventsArgs = nil
        observeLatestArgs = nil
        insertedEvents.removeAll()
        updatedEvents.removeAll()
        softDeletedEventIds.removeAll()
        countForDayArgs = nil
        shouldThrow = false
        mockCount = 0
    }
}

// MARK: - MockHealthRepository

/// Mock HealthRepository for ViewModel tests.
@Observable
@MainActor
final class MockHealthRepository {

    // MARK: - Published State

    var events: [HealthEvent] = []

    // MARK: - Call Tracking

    var observeEventsArgs: (childId: String, date: String)?
    var observeEventsByTypeArgs: (childId: String, date: String, type: HealthEventType)?
    var insertedEvents: [HealthEvent] = []
    var updatedEvents: [HealthEvent] = []
    var softDeletedEventIds: [String] = []
    var latestGrowthCalledForChildId: String?

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")
    var mockLatestGrowth: HealthEvent?

    // MARK: - Methods

    func observeEvents(childId: String, date: String) {
        observeEventsArgs = (childId: childId, date: date)
    }

    func observeEventsByType(childId: String, date: String, type: HealthEventType) {
        observeEventsByTypeArgs = (childId: childId, date: date, type: type)
    }

    func insert(event: HealthEvent) async throws {
        if shouldThrow { throw mockError }
        insertedEvents.append(event)
        events.append(event)
    }

    func update(event: HealthEvent) async throws {
        if shouldThrow { throw mockError }
        updatedEvents.append(event)
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }

    func softDelete(eventId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedEventIds.append(eventId)
        events.removeAll { $0.id == eventId }
    }

    func latestGrowth(childId: String) async throws -> HealthEvent? {
        latestGrowthCalledForChildId = childId
        if shouldThrow { throw mockError }
        return mockLatestGrowth
    }

    func reset() {
        events.removeAll()
        observeEventsArgs = nil
        observeEventsByTypeArgs = nil
        insertedEvents.removeAll()
        updatedEvents.removeAll()
        softDeletedEventIds.removeAll()
        latestGrowthCalledForChildId = nil
        shouldThrow = false
        mockLatestGrowth = nil
    }
}

// MARK: - MockActivityRepository

/// Mock ActivityRepository for ViewModel tests.
@Observable
@MainActor
final class MockActivityRepository {

    // MARK: - Published State

    var events: [ActivityEvent] = []

    // MARK: - Call Tracking

    var observeEventsArgs: (childId: String, date: String)?
    var insertedEvents: [ActivityEvent] = []
    var updatedEvents: [ActivityEvent] = []
    var softDeletedEventIds: [String] = []
    var totalDurationArgs: (childId: String, date: String, activityType: ActivityType)?

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")
    var mockTotalDuration = 0

    // MARK: - Methods

    func observeEvents(childId: String, date: String) {
        observeEventsArgs = (childId: childId, date: date)
    }

    func insert(event: ActivityEvent) async throws {
        if shouldThrow { throw mockError }
        insertedEvents.append(event)
        events.append(event)
    }

    func update(event: ActivityEvent) async throws {
        if shouldThrow { throw mockError }
        updatedEvents.append(event)
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }

    func softDelete(eventId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedEventIds.append(eventId)
        events.removeAll { $0.id == eventId }
    }

    func totalDurationForDay(childId: String, date: String, activityType: ActivityType) async throws -> Int {
        totalDurationArgs = (childId: childId, date: date, activityType: activityType)
        if shouldThrow { throw mockError }
        return mockTotalDuration
    }

    func reset() {
        events.removeAll()
        observeEventsArgs = nil
        insertedEvents.removeAll()
        updatedEvents.removeAll()
        softDeletedEventIds.removeAll()
        totalDurationArgs = nil
        shouldThrow = false
        mockTotalDuration = 0
    }
}

// MARK: - MockCustomItemRepository

/// Mock CustomItemRepository for ViewModel tests.
@Observable
@MainActor
final class MockCustomItemRepository {

    // MARK: - Published State

    var items: [CustomItem] = []

    // MARK: - Call Tracking

    var observeItemsArgs: (childId: String, category: CustomItemCategory)?
    var insertedItems: [CustomItem] = []
    var updatedItems: [CustomItem] = []
    var softDeletedItemIds: [String] = []

    // MARK: - Configuration

    var shouldThrow = false
    var mockError: Error = DittoManagerError.queryFailed("Mock repository error")

    // MARK: - Methods

    func observeItems(childId: String, category: CustomItemCategory) {
        observeItemsArgs = (childId: childId, category: category)
    }

    func insert(item: CustomItem) async throws {
        if shouldThrow { throw mockError }
        insertedItems.append(item)
        items.append(item)
    }

    func update(item: CustomItem) async throws {
        if shouldThrow { throw mockError }
        updatedItems.append(item)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    func softDelete(itemId: String) async throws {
        if shouldThrow { throw mockError }
        softDeletedItemIds.append(itemId)
        items.removeAll { $0.id == itemId }
    }

    func reset() {
        items.removeAll()
        observeItemsArgs = nil
        insertedItems.removeAll()
        updatedItems.removeAll()
        softDeletedItemIds.removeAll()
        shouldThrow = false
    }
}

// MARK: - ViewModel Protocol Conformances

// These conformances allow mock repositories to be injected into ViewModels
// via the data source protocols defined in HomeViewModel and SummaryViewModel.

extension MockFeedingRepository: HomeViewFeedingDataSource {}
extension MockFeedingRepository: SummaryViewFeedingDataSource {}
extension MockFeedingRepository: LogFeedingDataSource {}

extension MockDiaperRepository: HomeViewDiaperDataSource {}
extension MockDiaperRepository: SummaryViewDiaperDataSource {}
extension MockDiaperRepository: LogDiaperDataSource {}

extension MockActivityRepository: HomeViewActivityDataSource {}
extension MockActivityRepository: SummaryViewActivityDataSource {}

extension MockHealthRepository: HomeViewHealthDataSource {}
extension MockHealthRepository: SummaryViewHealthDataSource {}

extension MockChildRepository: JoinFamilyChildDataSource {}
extension MockChildRepository: RegisterChildDataSource {}
extension MockCustomItemRepository: LogFeedingCustomItemDataSource {}
