import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the SummaryViewModel, verifying event merging/sorting, stat calculations,
/// date navigation, and observation lifecycle.
@MainActor
struct SummaryViewModelTests {

    // MARK: - Helpers

    private func makeActiveChildState(with child: Child? = nil) -> ActiveChildState {
        let state = ActiveChildState()
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

    private func makeViewModel(
        feedingRepo: MockFeedingRepository? = nil,
        diaperRepo: MockDiaperRepository? = nil,
        healthRepo: MockHealthRepository? = nil,
        activityRepo: MockActivityRepository? = nil,
        activeChildState: ActiveChildState? = nil,
        child: Child? = nil
    ) -> (SummaryViewModel, MockFeedingRepository, MockDiaperRepository, MockHealthRepository, MockActivityRepository) {
        let feedingRepo = feedingRepo ?? MockFeedingRepository()
        let diaperRepo = diaperRepo ?? MockDiaperRepository()
        let healthRepo = healthRepo ?? MockHealthRepository()
        let activityRepo = activityRepo ?? MockActivityRepository()
        let state = activeChildState ?? makeActiveChildState(with: child)
        let vm = SummaryViewModel(
            feedingRepository: feedingRepo,
            diaperRepository: diaperRepo,
            healthRepository: healthRepo,
            activityRepository: activityRepo,
            activeChildState: state
        )
        return (vm, feedingRepo, diaperRepo, healthRepo, activityRepo)
    }

    // MARK: - Stat Calculation Tests

    @Test("Total feedings matches feeding repository event count")
    func totalFeedingsCount() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle),
            FeedingEvent(id: "f2", childId: "child-1", type: .breast),
            FeedingEvent(id: "f3", childId: "child-1", type: .solid),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        #expect(vm.totalFeedings == 3)
    }

    @Test("Total diapers matches diaper repository event count")
    func totalDiapersCount() {
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            DiaperEvent(id: "d1", childId: "child-1", type: .pee),
            DiaperEvent(id: "d2", childId: "child-1", type: .poop),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(diaperRepo: diaperRepo, child: child)

        #expect(vm.totalDiapers == 2)
    }

    @Test("Total activities matches activity repository event count")
    func totalActivitiesCount() {
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .bath),
            ActivityEvent(id: "a2", childId: "child-1", activityType: .tummyTime, durationMinutes: 30),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(activityRepo: activityRepo, child: child)

        #expect(vm.totalActivities == 2)
    }

    @Test("Total health events matches health repository event count")
    func totalHealthEventsCount() {
        let healthRepo = MockHealthRepository()
        healthRepo.events = [
            HealthEvent(id: "h1", childId: "child-1", type: .temperature, temperatureValue: 98.6, temperatureUnit: .fahrenheit),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(healthRepo: healthRepo, child: child)

        #expect(vm.totalHealthEvents == 1)
    }

    @Test("Total event count sums all categories")
    func totalEventCount() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle),
            FeedingEvent(id: "f2", childId: "child-1", type: .bottle),
        ]
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            DiaperEvent(id: "d1", childId: "child-1", type: .pee),
        ]
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .bath),
        ]
        let healthRepo = MockHealthRepository()
        healthRepo.events = [
            HealthEvent(id: "h1", childId: "child-1", type: .medicine, medicineName: "Tylenol"),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            healthRepo: healthRepo,
            activityRepo: activityRepo,
            child: child
        )

        #expect(vm.totalEventCount == 5)
    }

    @Test("All counts are zero when no events")
    func allCountsZero() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.totalFeedings == 0)
        #expect(vm.totalDiapers == 0)
        #expect(vm.totalActivities == 0)
        #expect(vm.totalHealthEvents == 0)
        #expect(vm.totalEventCount == 0)
    }

    // MARK: - All Events Merging and Sorting Tests

    @Test("allEvents merges and sorts by timestamp descending")
    func allEventsMergedAndSorted() {
        let now = Date()
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle, timestamp: now.addingTimeInterval(-3600)),
        ]
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            DiaperEvent(id: "d1", childId: "child-1", type: .pee, timestamp: now.addingTimeInterval(-1800)),
        ]
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .tummyTime, timestamp: now.addingTimeInterval(-7200), durationMinutes: 30),
        ]
        let healthRepo = MockHealthRepository()
        healthRepo.events = [
            HealthEvent(id: "h1", childId: "child-1", type: .temperature, timestamp: now),
        ]

        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            healthRepo: healthRepo,
            activityRepo: activityRepo,
            child: child
        )

        let events = vm.allEvents

        #expect(events.count == 4)

        // Should be sorted newest first
        #expect(events[0].id == "h1")    // now
        #expect(events[1].id == "d1")    // -30m
        #expect(events[2].id == "f1")    // -1h
        #expect(events[3].id == "a1")    // -2h
    }

    @Test("allEvents is empty when no events exist")
    func allEventsEmpty() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.allEvents.isEmpty)
    }

    @Test("allEvents correctly categorizes feeding events")
    func allEventsFeedingCategory() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle, bottleQuantity: 4, bottleQuantityUnit: .oz),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        let events = vm.allEvents
        #expect(events.count == 1)
        #expect(events[0].category == .feeding)
        #expect(events[0].title == "Bottle")
        #expect(!events[0].detail.isEmpty)
    }

    @Test("allEvents correctly categorizes diaper events")
    func allEventsDiaperCategory() {
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            DiaperEvent(id: "d1", childId: "child-1", type: .poop),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(diaperRepo: diaperRepo, child: child)

        let events = vm.allEvents
        #expect(events.count == 1)
        #expect(events[0].category == .diaper)
        #expect(events[0].title == "Poop")
    }

    @Test("allEvents correctly categorizes activity events")
    func allEventsActivityCategory() {
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .tummyTime, durationMinutes: 15),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(activityRepo: activityRepo, child: child)

        let events = vm.allEvents
        #expect(events.count == 1)
        #expect(events[0].category == .activity)
        #expect(events[0].title == "Tummy Time")
    }

    @Test("allEvents correctly categorizes health events")
    func allEventsHealthCategory() {
        let healthRepo = MockHealthRepository()
        healthRepo.events = [
            HealthEvent(id: "h1", childId: "child-1", type: .medicine, medicineName: "Tylenol"),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(healthRepo: healthRepo, child: child)

        let events = vm.allEvents
        #expect(events.count == 1)
        #expect(events[0].category == .health)
        #expect(events[0].title == "Medicine")
    }

    // MARK: - Hero Stat Tests

    @Test("Hero stat shows '0' when no events")
    func heroStatEmpty() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.heroStatLabel == "0")
        #expect(vm.heroStatSubtitle == "Total Events")
    }

    @Test("Hero stat shows total tracked time when activities have durations")
    func heroStatWithDurations() {
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .tummyTime, durationMinutes: 90),
            ActivityEvent(id: "a2", childId: "child-1", activityType: .storyTime, durationMinutes: 30),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(activityRepo: activityRepo, child: child)

        #expect(vm.heroStatLabel == "2h 0m")
        #expect(vm.heroStatSubtitle == "Total Tracked Time")
    }

    @Test("Hero stat shows minutes-only when less than an hour")
    func heroStatMinutesOnly() {
        let activityRepo = MockActivityRepository()
        activityRepo.events = [
            ActivityEvent(id: "a1", childId: "child-1", activityType: .tummyTime, durationMinutes: 45),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(activityRepo: activityRepo, child: child)

        #expect(vm.heroStatLabel == "45m")
        #expect(vm.heroStatSubtitle == "Total Tracked Time")
    }

    @Test("Hero stat shows event count when no activity durations")
    func heroStatEventCount() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle),
            FeedingEvent(id: "f2", childId: "child-1", type: .bottle),
        ]
        let diaperRepo = MockDiaperRepository()
        diaperRepo.events = [
            DiaperEvent(id: "d1", childId: "child-1", type: .pee),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            child: child
        )

        #expect(vm.heroStatLabel == "3")
        #expect(vm.heroStatSubtitle == "Total Events")
    }

    // MARK: - Date Navigation Tests

    @Test("Selected date defaults to today")
    func selectedDateDefaultsToToday() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.isToday)
        #expect(!vm.canGoForward)
    }

    @Test("goToPreviousDay moves to yesterday")
    func goToPreviousDay() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        vm.onAppear()
        vm.goToPreviousDay()

        #expect(!vm.isToday)
        #expect(vm.canGoForward)
    }

    @Test("goToNextDay moves forward one day")
    func goToNextDay() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        vm.onAppear()
        vm.goToPreviousDay()
        vm.goToPreviousDay()

        #expect(vm.canGoForward)
        vm.goToNextDay()
        // Should still be before today
        #expect(!vm.isToday)
        #expect(vm.canGoForward)
    }

    @Test("goToNextDay does nothing when already today")
    func goToNextDayAtToday() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        let beforeDate = vm.selectedDate
        vm.goToNextDay()

        #expect(vm.isToday)
        // Date should not have changed
        #expect(Calendar.current.isDate(vm.selectedDate, inSameDayAs: beforeDate))
    }

    @Test("Date navigation reloads observations")
    func dateNavigationReloadsObservations() {
        let feedingRepo = MockFeedingRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        let firstDate = feedingRepo.observeEventsArgs?.date

        vm.goToPreviousDay()
        let secondDate = feedingRepo.observeEventsArgs?.date

        #expect(firstDate != nil)
        #expect(secondDate != nil)
        #expect(firstDate != secondDate)
    }

    @Test("selectedDateDisplay returns formatted date string")
    func selectedDateDisplayFormatted() {
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(child: child)

        let display = vm.selectedDateDisplay
        #expect(!display.isEmpty)
        // Should contain the current year
        let year = Calendar.current.component(.year, from: Date())
        #expect(display.contains(String(year)))
    }

    // MARK: - Observation Lifecycle Tests

    @Test("onAppear starts observing for the active child")
    func onAppearStartsObserving() {
        let feedingRepo = MockFeedingRepository()
        let diaperRepo = MockDiaperRepository()
        let healthRepo = MockHealthRepository()
        let activityRepo = MockActivityRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            healthRepo: healthRepo,
            activityRepo: activityRepo,
            child: child
        )

        vm.onAppear()

        #expect(vm.observedChildId == "child-1")
        #expect(feedingRepo.observeEventsArgs?.childId == "child-1")
        #expect(diaperRepo.observeEventsArgs?.childId == "child-1")
        #expect(healthRepo.observeEventsArgs?.childId == "child-1")
        #expect(activityRepo.observeEventsArgs?.childId == "child-1")
    }

    @Test("onAppear does nothing when no active child")
    func onAppearNoChild() {
        let feedingRepo = MockFeedingRepository()
        let (vm, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo)

        vm.onAppear()

        #expect(vm.observedChildId == nil)
        #expect(feedingRepo.observeEventsArgs == nil)
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
        let state = ActiveChildState()
        state.updateChildren([child1, child2])

        let (vm, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            activeChildState: state
        )

        vm.onAppear()
        #expect(vm.observedChildId == "child-1")

        state.selectChild("child-2")
        vm.onChildChanged()
        #expect(vm.observedChildId == "child-2")
        #expect(feedingRepo.observeEventsArgs?.childId == "child-2")
    }

    @Test("onChildChanged does nothing when same child")
    func onChildChangedSameChild() {
        let feedingRepo = MockFeedingRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        feedingRepo.observeEventsArgs = nil

        vm.onChildChanged()
        #expect(feedingRepo.observeEventsArgs == nil)
    }

    // MARK: - TimelineEvent Factory Tests

    @Test("TimelineEvent.from(FeedingEvent) creates correct event")
    func timelineEventFromFeeding() {
        let feeding = FeedingEvent(
            id: "f1",
            childId: "child-1",
            type: .bottle,
            bottleQuantity: 4,
            bottleQuantityUnit: .oz
        )
        let event = TimelineEvent.from(feeding)

        #expect(event.id == "f1")
        #expect(event.category == .feeding)
        #expect(event.title == "Bottle")
        #expect(!event.detail.isEmpty)
        #expect(event.iconName == FeedingType.bottle.iconName)
    }

    @Test("TimelineEvent.from(DiaperEvent) creates correct event")
    func timelineEventFromDiaper() {
        let diaper = DiaperEvent(id: "d1", childId: "child-1", type: .poop)
        let event = TimelineEvent.from(diaper)

        #expect(event.id == "d1")
        #expect(event.category == .diaper)
        #expect(event.title == "Poop")
        #expect(event.iconName == DiaperType.poop.iconName)
    }

    @Test("TimelineEvent.from(HealthEvent) creates correct event")
    func timelineEventFromHealth() {
        let health = HealthEvent(
            id: "h1",
            childId: "child-1",
            type: .temperature,
            temperatureValue: 98.6,
            temperatureUnit: .fahrenheit
        )
        let event = TimelineEvent.from(health)

        #expect(event.id == "h1")
        #expect(event.category == .health)
        #expect(event.title == "Temperature")
        #expect(event.iconName == HealthEventType.temperature.iconName)
    }

    @Test("TimelineEvent.from(ActivityEvent) creates correct event")
    func timelineEventFromActivity() {
        let activity = ActivityEvent(
            id: "a1",
            childId: "child-1",
            activityType: .storyTime,
            durationMinutes: 20
        )
        let event = TimelineEvent.from(activity)

        #expect(event.id == "a1")
        #expect(event.category == .activity)
        #expect(event.title == "Story Time")
        #expect(event.iconName == ActivityType.storyTime.iconName)
        #expect(event.detail.contains("20 min"))
    }

    @Test("TimelineEvent.timeString returns formatted time")
    func timelineEventTimeString() {
        let event = TimelineEvent(
            id: "test",
            timestamp: Date(),
            category: .feeding,
            iconName: "baby.bottle",
            title: "Bottle",
            detail: "Test"
        )

        #expect(!event.timeString.isEmpty)
    }
}
