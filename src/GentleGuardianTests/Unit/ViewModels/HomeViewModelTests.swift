import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the HomeViewModel, verifying greeting generation, last feeding/diaper
/// properties, today counts, and observation lifecycle.
@MainActor
struct HomeViewModelTests {

    // MARK: - Helpers

    private func makeActiveChildState(with child: Child? = nil) -> ActiveChildState {
        let isolated = UserDefaults(suiteName: UUID().uuidString)!
        let state = ActiveChildState(userDefaults: isolated)
        if let child {
            state.updateChildren([child])
        }
        return state
    }

    private func makeSampleChild() -> Child {
        Child(
            id: "child-1",
            firstName: "Liam",
            birthday: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            sex: .male,
            syncCode: "ABC123"
        )
    }

    private func makeSampleFeeding(
        id: String = "feeding-1",
        childId: String = "child-1",
        type: FeedingType = .bottle,
        timestamp: Date = Date(),
        bottleQuantity: Double? = 4.0,
        bottleQuantityUnit: VolumeUnit? = .oz,
        formulaType: String? = "Formula"
    ) -> FeedingEvent {
        FeedingEvent(
            id: id,
            childId: childId,
            type: type,
            timestamp: timestamp,
            bottleQuantity: bottleQuantity,
            bottleQuantityUnit: bottleQuantityUnit,
            formulaType: formulaType
        )
    }

    private func makeSampleDiaper(
        id: String = "diaper-1",
        childId: String = "child-1",
        type: DiaperType = .pee,
        timestamp: Date = Date()
    ) -> DiaperEvent {
        DiaperEvent(
            id: id,
            childId: childId,
            type: type,
            timestamp: timestamp
        )
    }

    private func makeViewModel(
        feedingRepo: MockFeedingRepository? = nil,
        diaperRepo: MockDiaperRepository? = nil,
        activityRepo: MockActivityRepository? = nil,
        healthRepo: MockHealthRepository? = nil,
        sleepRepo: MockSleepRepository? = nil,
        otherRepo: MockOtherEventRepository? = nil,
        activeChildState: ActiveChildState? = nil,
        child: Child? = nil
    ) -> (HomeViewModel, MockFeedingRepository, MockDiaperRepository, MockActivityRepository, MockHealthRepository, MockSleepRepository, MockOtherEventRepository) {
        let feedingRepo = feedingRepo ?? MockFeedingRepository()
        let diaperRepo = diaperRepo ?? MockDiaperRepository()
        let activityRepo = activityRepo ?? MockActivityRepository()
        let healthRepo = healthRepo ?? MockHealthRepository()
        let sleepRepo = sleepRepo ?? MockSleepRepository()
        let otherRepo = otherRepo ?? MockOtherEventRepository()
        let state = activeChildState ?? makeActiveChildState(with: child)
        let vm = HomeViewModel(
            feedingRepository: feedingRepo,
            diaperRepository: diaperRepo,
            activityRepository: activityRepo,
            healthRepository: healthRepo,
            sleepRepository: sleepRepo,
            otherEventRepository: otherRepo,
            activeChildState: state
        )
        return (vm, feedingRepo, diaperRepo, activityRepo, healthRepo, sleepRepo, otherRepo)
    }

    // MARK: - Greeting Tests

    @Test("Greeting returns a non-empty string containing 'Good'")
    func greetingIsNonEmpty() {
        let (vm, _, _, _, _, _, _) = makeViewModel()

        #expect(!vm.greeting.isEmpty)
        #expect(vm.greeting.contains("Good"))
    }

    @Test("Child first name is nil when no child is selected")
    func childFirstNameNilWhenNoChild() {
        let (vm, _, _, _, _, _, _) = makeViewModel()

        #expect(vm.childFirstName == nil)
    }

    @Test("Child first name is populated when child is active")
    func childFirstNamePopulated() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.childFirstName == "Liam")
    }

    @Test("Greeting subtitle includes child name when child is active")
    func greetingSubtitleWithChild() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.greetingSubtitle.contains("Liam"))
        #expect(vm.greetingSubtitle.contains("old"))
    }

    @Test("Greeting subtitle shows welcome when no child")
    func greetingSubtitleNoChild() {
        let (vm, _, _, _, _, _, _) = makeViewModel()

        #expect(vm.greetingSubtitle == "Welcome to Gentle Guardian")
    }

    // MARK: - Last Feeding Tests

    @Test("Last feeding shows 'No feedings yet' when no data")
    func lastFeedingEmptyState() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.lastFeeding == nil)
        #expect(vm.lastFeedingTypeLabel == "No feedings yet")
        #expect(vm.lastFeedingTimeString == "--")
        #expect(vm.lastFeedingRelativeTime == "")
        #expect(vm.lastFeedingDetail == "")
    }

    @Test("Last feeding shows bottle type with formula name")
    func lastFeedingBottleWithFormula() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = makeSampleFeeding(formulaType: "Similac")
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Similac Bottle")
        #expect(vm.lastFeedingTimeString != "--")
        #expect(!vm.lastFeedingRelativeTime.isEmpty)
    }

    @Test("Last feeding shows 'Bottle' when no formula specified")
    func lastFeedingBottleWithoutFormula() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = makeSampleFeeding(formulaType: nil)
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Bottle")
    }

    @Test("Last feeding shows 'Bottle' when formula is empty string")
    func lastFeedingBottleEmptyFormula() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = makeSampleFeeding(formulaType: "")
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Bottle")
    }

    @Test("Last feeding shows breast type with side")
    func lastFeedingBreast() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = FeedingEvent(
            id: "f-breast",
            childId: "child-1",
            type: .breast,
            breastDurationMinutes: 15,
            breastSide: .left
        )
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Breast (Left)")
    }

    @Test("Last feeding shows breast type without side")
    func lastFeedingBreastNoSide() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = FeedingEvent(
            id: "f-breast",
            childId: "child-1",
            type: .breast,
            breastDurationMinutes: 15,
            breastSide: nil
        )
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Breast")
    }

    @Test("Last feeding shows solid food name")
    func lastFeedingSolid() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = FeedingEvent(
            id: "f-solid",
            childId: "child-1",
            type: .solid,
            solidType: "Banana"
        )
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Banana")
    }

    @Test("Last feeding shows 'Solid Food' when no solid type specified")
    func lastFeedingSolidNoType() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = FeedingEvent(
            id: "f-solid",
            childId: "child-1",
            type: .solid,
            solidType: nil
        )
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.lastFeedingTypeLabel == "Solid Food")
    }

    @Test("Last feeding detail returns event summary")
    func lastFeedingDetailShowsSummary() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.latestEvent = makeSampleFeeding(
            bottleQuantity: 4.0,
            bottleQuantityUnit: .oz,
            formulaType: "Formula"
        )
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(!vm.lastFeedingDetail.isEmpty)
        #expect(vm.lastFeedingDetail.contains("oz"))
    }

    // MARK: - Diaper Status Tests

    @Test("Diaper status shows 'No data' when no events")
    func diaperEmptyState() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.diaperStatusLabel == "No data")
        #expect(vm.diaperRelativeTime == "")
    }

    @Test("Diaper status shows 'Clean' when there is a latest event")
    func diaperCleanState() {
        let diaperRepo = MockDiaperRepository()
        diaperRepo.latestEvent = makeSampleDiaper()
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(diaperRepo: diaperRepo, child: child)

        #expect(vm.diaperStatusLabel == "Clean")
        #expect(!vm.diaperRelativeTime.isEmpty)
    }

    // MARK: - Today Counts Tests

    @Test("Today counts reflect repository event arrays")
    func todayCounts() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            makeSampleFeeding(id: "f1"),
            makeSampleFeeding(id: "f2"),
            makeSampleFeeding(id: "f3"),
        ]
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            makeSampleDiaper(id: "d1"),
            makeSampleDiaper(id: "d2"),
        ]
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .bath),
        ]
        let healthRepo = MockHealthRepository()

        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            activityRepo: activityRepo,
            healthRepo: healthRepo,
            child: child
        )

        #expect(vm.todayFeedingCount == 3)
        #expect(vm.todayDiaperCount == 2)
        #expect(vm.todayActivityCount == 1)
        #expect(vm.todayHealthCount == 0)
    }

    @Test("Today counts are zero when no events")
    func todayCountsEmpty() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.todayFeedingCount == 0)
        #expect(vm.todayDiaperCount == 0)
        #expect(vm.todayActivityCount == 0)
        #expect(vm.todayHealthCount == 0)
    }

    // MARK: - Observation Lifecycle Tests

    @Test("onAppear starts observing for the active child")
    func onAppearStartsObserving() {
        let feedingRepo = MockFeedingRepository()
        let diaperRepo = MockDiaperRepository()
        let activityRepo = MockActivityRepository()
        let healthRepo = MockHealthRepository()
        let sleepRepo = MockSleepRepository()
        let otherRepo = MockOtherEventRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            activityRepo: activityRepo,
            healthRepo: healthRepo,
            sleepRepo: sleepRepo,
            otherRepo: otherRepo,
            child: child
        )

        vm.onAppear()

        #expect(vm.observedChildId == "child-1")
        #expect(feedingRepo.observeEventsArgs?.childId == "child-1")
        #expect(feedingRepo.observeLatestArgs == "child-1")
        #expect(diaperRepo.observeEventsArgs?.childId == "child-1")
        #expect(diaperRepo.observeLatestArgs == "child-1")
        #expect(activityRepo.observeEventsArgs?.childId == "child-1")
        #expect(healthRepo.observeEventsArgs?.childId == "child-1")
        #expect(sleepRepo.observeEventsArgs?.childId == "child-1")
        #expect(otherRepo.observeEventsArgs?.childId == "child-1")
    }

    @Test("onAppear does nothing when no active child")
    func onAppearNoChild() {
        let feedingRepo = MockFeedingRepository()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo)

        vm.onAppear()

        #expect(vm.observedChildId == nil)
        #expect(feedingRepo.observeEventsArgs == nil)
    }

    @Test("onAppear sets todayString")
    func onAppearSetsTodayString() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        vm.onAppear()

        #expect(vm.todayString == DateService.todayString())
    }

    @Test("onChildChanged restarts observation for new child")
    func onChildChangedRestartsObservation() {
        let feedingRepo = MockFeedingRepository()
        let child1 = makeSampleChild()
        let child2 = Child(
            id: "child-2",
            firstName: "Emma",
            birthday: Date(),
            sex: .female,
            syncCode: "DEF456"
        )
        let state = ActiveChildState(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        state.updateChildren([child1, child2])

        let (vm, _, _, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            activeChildState: state
        )

        vm.onAppear()
        #expect(vm.observedChildId == "child-1")

        // Switch to child-2
        state.selectChild("child-2")
        vm.onChildChanged()
        #expect(vm.observedChildId == "child-2")
        #expect(feedingRepo.observeEventsArgs?.childId == "child-2")
    }

    @Test("onChildChanged does nothing when same child")
    func onChildChangedSameChild() {
        let feedingRepo = MockFeedingRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        feedingRepo.observeEventsArgs = nil // Reset tracking

        vm.onChildChanged()
        #expect(feedingRepo.observeEventsArgs == nil) // Should not re-observe
    }

    // MARK: - Quick Log Tests

    @Test("Quick log tapped sets selectedEventCategory")
    func quickLogSetsCategory() {
        let (vm, _, _, _, _, _, _) = makeViewModel()

        #expect(vm.selectedEventCategory == nil)

        vm.quickLogTapped(.feeding)
        #expect(vm.selectedEventCategory == .feeding)

        vm.quickLogTapped(.diaper)
        #expect(vm.selectedEventCategory == .diaper)

        vm.quickLogTapped(.health)
        #expect(vm.selectedEventCategory == .health)

        vm.quickLogTapped(.activity)
        #expect(vm.selectedEventCategory == .activity)
    }

    // MARK: - Sleep Duration Tests

    @Test("Sleep duration shows 'No data' when no sleep events")
    func sleepDurationNoData() {
        let (vm, _, _, _, _, _, _) = makeViewModel()

        #expect(vm.sleepDurationLabel == "No data")
    }

    @Test("Sleep duration shows minutes when under 60")
    func sleepDurationMinutesOnly() {
        let sleepRepo = MockSleepRepository()
        let now = Date()
        sleepRepo.events = [
            SleepEvent(childId: "child-1", startTime: now.addingTimeInterval(-2700), endTime: now)
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(sleepRepo: sleepRepo, child: child)

        #expect(vm.sleepDurationLabel == "45m")
    }

    @Test("Sleep duration shows hours and minutes when over 60")
    func sleepDurationHoursAndMinutes() {
        let sleepRepo = MockSleepRepository()
        let now = Date()
        sleepRepo.events = [
            SleepEvent(childId: "child-1", startTime: now.addingTimeInterval(-5400), endTime: now.addingTimeInterval(-3600)),
            SleepEvent(childId: "child-1", startTime: now.addingTimeInterval(-3600), endTime: now)
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(sleepRepo: sleepRepo, child: child)

        #expect(vm.sleepDurationLabel == "1h 30m")
    }

    @Test("Sleep duration shows hours only when exactly divisible")
    func sleepDurationExactHours() {
        let sleepRepo = MockSleepRepository()
        let now = Date()
        sleepRepo.events = [
            SleepEvent(childId: "child-1", startTime: now.addingTimeInterval(-7200), endTime: now)
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(sleepRepo: sleepRepo, child: child)

        #expect(vm.sleepDurationLabel == "2h")
    }

    // MARK: - Other Event Count Tests

    @Test("Today other count reflects repository event array")
    func todayOtherCount() {
        let otherRepo = MockOtherEventRepository()
        otherRepo.events = [
            OtherEvent(id: "o1", childId: "child-1", name: "Massage"),
            OtherEvent(id: "o2", childId: "child-1", name: "Music class"),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(otherRepo: otherRepo, child: child)

        #expect(vm.todayOtherCount == 2)
    }

    @Test("Today other count is zero when no events")
    func todayOtherCountEmpty() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.todayOtherCount == 0)
    }
}
