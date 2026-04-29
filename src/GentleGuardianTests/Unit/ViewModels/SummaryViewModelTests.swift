import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the SummaryViewModel, verifying section selection, food ranking
/// aggregation/filtering, growth fetch, event merging, date navigation, and
/// observation lifecycle.
@MainActor
struct SummaryViewModelTests {

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

    private func makeViewModel(
        feedingRepo: MockFeedingRepository? = nil,
        diaperRepo: MockDiaperRepository? = nil,
        healthRepo: MockHealthRepository? = nil,
        activityRepo: MockActivityRepository? = nil,
        sleepRepo: MockSleepRepository? = nil,
        otherRepo: MockOtherEventRepository? = nil,
        activeChildState: ActiveChildState? = nil,
        child: Child? = nil
    ) -> (SummaryViewModel, MockFeedingRepository, MockDiaperRepository, MockHealthRepository, MockActivityRepository, MockSleepRepository, MockOtherEventRepository) {
        let feedingRepo = feedingRepo ?? MockFeedingRepository()
        let diaperRepo = diaperRepo ?? MockDiaperRepository()
        let healthRepo = healthRepo ?? MockHealthRepository()
        let activityRepo = activityRepo ?? MockActivityRepository()
        let sleepRepo = sleepRepo ?? MockSleepRepository()
        let otherRepo = otherRepo ?? MockOtherEventRepository()
        let state = activeChildState ?? makeActiveChildState(with: child)
        let vm = SummaryViewModel(
            feedingRepository: feedingRepo,
            diaperRepository: diaperRepo,
            healthRepository: healthRepo,
            activityRepository: activityRepo,
            sleepRepository: sleepRepo,
            otherEventRepository: otherRepo,
            activeChildState: state
        )
        return (vm, feedingRepo, diaperRepo, healthRepo, activityRepo, sleepRepo, otherRepo)
    }

    // MARK: - Section Selection

    @Test("Selected section defaults to activity feed")
    func defaultSection() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.selectedSection == .activityFeed)
    }

    @Test("SummarySection display names are user-friendly")
    func sectionDisplayNames() {
        #expect(SummarySection.activityFeed.displayName == "Activity Feed")
        #expect(SummarySection.growth.displayName == "Growth")
        #expect(SummarySection.foodRanking.displayName == "Food Ranking")
    }

    @Test("FoodRankingFilter display names are user-friendly")
    func filterDisplayNames() {
        #expect(FoodRankingFilter.all.displayName == "All")
        #expect(FoodRankingFilter.liked.displayName == "Liked")
        #expect(FoodRankingFilter.hated.displayName == "Hated")
    }

    // MARK: - Growth Loading

    @Test("loadGrowthEvents populates growthEvents from data source")
    func loadGrowthEventsPopulates() async {
        let healthRepo = MockHealthRepository()
        let now = Date()
        healthRepo.mockAllGrowth = [
            HealthEvent(id: "h2", childId: "child-1", type: .growth, timestamp: now,
                        heightValue: 70, heightUnit: .cm),
            HealthEvent(id: "h1", childId: "child-1", type: .growth,
                        timestamp: now.addingTimeInterval(-86400),
                        heightValue: 68, heightUnit: .cm),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(healthRepo: healthRepo, child: child)

        vm.onAppear()
        await vm.loadGrowthEvents()

        #expect(vm.growthEvents.count == 2)
        #expect(healthRepo.fetchAllGrowthCalledForChildId == "child-1")
        #expect(vm.growthEvents.first?.id == "h2")
    }

    @Test("loadGrowthEvents resets to empty when data source throws")
    func loadGrowthEventsHandlesError() async {
        let healthRepo = MockHealthRepository()
        healthRepo.shouldThrow = true
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(healthRepo: healthRepo, child: child)

        vm.onAppear()
        await vm.loadGrowthEvents()

        #expect(vm.growthEvents.isEmpty)
    }

    @Test("loadGrowthEvents is a no-op without an active child")
    func loadGrowthEventsNoChild() async {
        let healthRepo = MockHealthRepository()
        healthRepo.mockAllGrowth = [
            HealthEvent(id: "h1", childId: "x", type: .growth),
        ]
        let (vm, _, _, _, _, _, _) = makeViewModel(healthRepo: healthRepo)

        await vm.loadGrowthEvents()

        #expect(vm.growthEvents.isEmpty)
        #expect(healthRepo.fetchAllGrowthCalledForChildId == nil)
    }

    // MARK: - Food Ranking

    @Test("loadSolidFeedings populates solidFeedings from data source")
    func loadSolidFeedingsPopulates() async {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.mockSolidFeedings = [
            FeedingEvent(id: "f1", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        await vm.loadSolidFeedings()

        #expect(vm.solidFeedings.count == 1)
        #expect(feedingRepo.fetchAllSolidFeedingsCalledForChildId == "child-1")
    }

    @Test("foodSummaries excludes foods with no rating")
    func foodSummariesExcludesUnrated() async {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.mockSolidFeedings = [
            FeedingEvent(id: "f1", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "f2", childId: "child-1", type: .solid,
                         solidType: "Banana", solidReaction: nil),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        await vm.loadSolidFeedings()

        let summaries = vm.foodSummaries
        #expect(summaries.count == 1)
        #expect(summaries.first?.foodName == "Avocado")
    }

    @Test("filteredFoodSummaries .liked surfaces foods with more happy than frown, sorted by score desc")
    func filteredFoodSummariesLiked() async {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.mockSolidFeedings = [
            // Avocado: 2 happy, 0 frown, score = +1.0
            FeedingEvent(id: "a1", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "a2", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
            // Banana: 2 happy, 1 frown, score = +1/3
            FeedingEvent(id: "b1", childId: "child-1", type: .solid,
                         solidType: "Banana", solidReaction: .happy),
            FeedingEvent(id: "b2", childId: "child-1", type: .solid,
                         solidType: "Banana", solidReaction: .happy),
            FeedingEvent(id: "b3", childId: "child-1", type: .solid,
                         solidType: "Banana", solidReaction: .frown),
            // Broccoli: 0 happy, 1 frown — should not appear in .liked
            FeedingEvent(id: "br1", childId: "child-1", type: .solid,
                         solidType: "Broccoli", solidReaction: .frown),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        await vm.loadSolidFeedings()
        vm.foodRankingFilter = .liked

        let liked = vm.filteredFoodSummaries
        #expect(liked.count == 2)
        #expect(liked[0].foodName == "Avocado")
        #expect(liked[1].foodName == "Banana")
    }

    @Test("filteredFoodSummaries .hated surfaces foods with more frown than happy, most-disliked first")
    func filteredFoodSummariesHated() async {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.mockSolidFeedings = [
            // Broccoli: 0 happy, 2 frown, score = -1.0
            FeedingEvent(id: "br1", childId: "child-1", type: .solid,
                         solidType: "Broccoli", solidReaction: .frown),
            FeedingEvent(id: "br2", childId: "child-1", type: .solid,
                         solidType: "Broccoli", solidReaction: .frown),
            // Spinach: 1 happy, 2 frown, score = -1/3
            FeedingEvent(id: "s1", childId: "child-1", type: .solid,
                         solidType: "Spinach", solidReaction: .happy),
            FeedingEvent(id: "s2", childId: "child-1", type: .solid,
                         solidType: "Spinach", solidReaction: .frown),
            FeedingEvent(id: "s3", childId: "child-1", type: .solid,
                         solidType: "Spinach", solidReaction: .frown),
            // Avocado: only happy — should not appear in .hated
            FeedingEvent(id: "a1", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        await vm.loadSolidFeedings()
        vm.foodRankingFilter = .hated

        let hated = vm.filteredFoodSummaries
        #expect(hated.count == 2)
        #expect(hated[0].foodName == "Broccoli")  // worst score first
        #expect(hated[1].foodName == "Spinach")
    }

    @Test("filteredFoodSummaries .all sorts by score descending")
    func filteredFoodSummariesAll() async {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.mockSolidFeedings = [
            FeedingEvent(id: "a1", childId: "child-1", type: .solid,
                         solidType: "Avocado", solidReaction: .happy),
            FeedingEvent(id: "br1", childId: "child-1", type: .solid,
                         solidType: "Broccoli", solidReaction: .frown),
            FeedingEvent(id: "n1", childId: "child-1", type: .solid,
                         solidType: "Carrot", solidReaction: .neutral),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

        vm.onAppear()
        await vm.loadSolidFeedings()

        let all = vm.filteredFoodSummaries
        #expect(all.count == 3)
        #expect(all[0].foodName == "Avocado")     // score +1
        #expect(all[1].foodName == "Carrot")      // score 0
        #expect(all[2].foodName == "Broccoli")    // score -1
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
        let (vm, _, _, _, _, _, _) = makeViewModel(
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
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.allEvents.isEmpty)
    }

    @Test("allEvents correctly categorizes feeding events")
    func allEventsFeedingCategory() {
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle, bottleQuantity: 4, bottleQuantityUnit: .oz),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(diaperRepo: diaperRepo, child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(activityRepo: activityRepo, child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(healthRepo: healthRepo, child: child)

        let events = vm.allEvents
        #expect(events.count == 1)
        #expect(events[0].category == .health)
        #expect(events[0].title == "Medicine")
    }

    // MARK: - Date Navigation Tests

    @Test("Selected date defaults to today")
    func selectedDateDefaultsToToday() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        #expect(vm.isToday)
        #expect(!vm.canGoForward)
    }

    @Test("goToPreviousDay moves to yesterday")
    func goToPreviousDay() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

        vm.onAppear()
        vm.goToPreviousDay()

        #expect(!vm.isToday)
        #expect(vm.canGoForward)
    }

    @Test("goToNextDay moves forward one day")
    func goToNextDay() {
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(feedingRepo: feedingRepo, child: child)

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
        let (vm, _, _, _, _, _, _) = makeViewModel(child: child)

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
        let sleepRepo = MockSleepRepository()
        let otherRepo = MockOtherEventRepository()
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            diaperRepo: diaperRepo,
            healthRepo: healthRepo,
            activityRepo: activityRepo,
            sleepRepo: sleepRepo,
            otherRepo: otherRepo,
            child: child
        )

        vm.onAppear()

        #expect(vm.observedChildId == "child-1")
        #expect(feedingRepo.observeEventsArgs?.childId == "child-1")
        #expect(diaperRepo.observeEventsArgs?.childId == "child-1")
        #expect(healthRepo.observeEventsArgs?.childId == "child-1")
        #expect(activityRepo.observeEventsArgs?.childId == "child-1")
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

    @Test("TimelineEvent.from(SleepEvent) creates correct event")
    func timelineEventFromSleep() {
        let now = Date()
        let sleep = SleepEvent(
            id: "s1",
            childId: "child-1",
            startTime: now.addingTimeInterval(-3600),
            endTime: now
        )
        let event = TimelineEvent.from(sleep)

        #expect(event.id == "s1")
        #expect(event.category == .sleep)
        #expect(event.title == "Sleep")
        #expect(event.iconName == "moon.fill")
        #expect(!event.detail.isEmpty)
    }

    @Test("TimelineEvent.timeString returns formatted time")
    func timelineEventTimeString() {
        let feeding = FeedingEvent(id: "test", childId: "child-1", type: .bottle)
        let event = TimelineEvent.from(feeding)

        #expect(!event.timeString.isEmpty)
    }

    // MARK: - Other Event Tests

    @Test("TimelineEvent.from(OtherEvent) creates correct event")
    func timelineEventFromOther() {
        let other = OtherEvent(
            id: "o1",
            childId: "child-1",
            name: "Massage",
            durationMinutes: 15
        )
        let event = TimelineEvent.from(other)

        #expect(event.id == "o1")
        #expect(event.category == .other)
        #expect(event.title == "Massage")
        #expect(event.iconName == "pencil.and.outline")
        #expect(event.detail.contains("15 min"))
    }

    @Test("allEvents includes other events in merged timeline")
    func allEventsIncludesOther() {
        let now = Date()
        let otherRepo = MockOtherEventRepository()
        otherRepo.events = [
            OtherEvent(id: "o1", childId: "child-1", name: "Massage", timestamp: now),
        ]
        let feedingRepo = MockFeedingRepository()
        feedingRepo.events = [
            FeedingEvent(id: "f1", childId: "child-1", type: .bottle, timestamp: now.addingTimeInterval(-3600)),
        ]
        let child = makeSampleChild()
        let (vm, _, _, _, _, _, _) = makeViewModel(
            feedingRepo: feedingRepo,
            otherRepo: otherRepo,
            child: child
        )

        let events = vm.allEvents
        #expect(events.count == 2)
        #expect(events[0].id == "o1") // most recent
        #expect(events[1].id == "f1")
    }
}
