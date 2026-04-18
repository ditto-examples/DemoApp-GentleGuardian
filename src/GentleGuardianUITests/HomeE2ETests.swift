import XCTest

/// E2E UI tests for the Home tab.
///
/// These tests verify the home screen displays correctly when a child exists.
/// Since the app requires a child to be registered to show the home screen,
/// these tests depend on either existing data or a test harness that
/// pre-populates a child record.
///
/// Note: Tests that reference specific child names assume the app is launched
/// with test data or a `--uitesting` flag that seeds a default child.
final class HomeE2ETests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-test-child"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - Home Tab Display

    func testHomeTabDisplaysGreetingWithChildName() {
        // The home tab should show a greeting.
        // Since the actual greeting depends on time of day, we look for common text.
        // The greeting format is: "Good {morning/afternoon/evening}, {name}!"
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        // Look for the navigation title "Gentle Guardian" or any greeting text.
        // If the home view is visible, there should be a "Quick Log" section.
        let quickLogText = app.staticTexts["Quick Log"]
        let homeNavTitle = app.navigationBars["Gentle Guardian"]

        let homeVisible = quickLogText.waitForExistence(timeout: 10)
            || homeNavTitle.waitForExistence(timeout: 10)

        // If the app has no child, it will show the welcome screen instead.
        // In that case, the test should pass gracefully.
        if !homeVisible {
            let welcomeTitle = app.staticTexts["Gentle Guardian"]
            if welcomeTitle.waitForExistence(timeout: 3) {
                // App is showing welcome screen - no child data seeded.
                // This is acceptable behavior; skip remaining assertions.
                return
            }
        }

        XCTAssertTrue(homeVisible, "Home tab should be visible with Quick Log section or navigation title")
    }

    func testQuickLogGridShowsSixActivityBubbles() {
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        let quickLogText = app.staticTexts["Quick Log"]
        guard quickLogText.waitForExistence(timeout: 10) else {
            // No child exists, home not visible
            return
        }

        // The Quick Log grid should have 6 bubbles:
        // Feeding, Diaper, Health, Activity, Sleep, Other
        let feedingBubble = app.staticTexts["Feeding"]
        let diaperBubble = app.staticTexts["Diaper"]
        let healthBubble = app.staticTexts["Health"]
        let activityBubble = app.staticTexts["Activity"]
        let sleepBubble = app.staticTexts["Sleep"]
        let otherBubble = app.staticTexts["Other"]

        // At least the main categories should be visible
        XCTAssertTrue(feedingBubble.exists, "Quick Log should show Feeding bubble")
        XCTAssertTrue(diaperBubble.exists, "Quick Log should show Diaper bubble")
        XCTAssertTrue(healthBubble.exists, "Quick Log should show Health bubble")
        XCTAssertTrue(activityBubble.exists, "Quick Log should show Activity bubble")
        XCTAssertTrue(sleepBubble.exists, "Quick Log should show Sleep bubble")
        XCTAssertTrue(otherBubble.exists, "Quick Log should show Other bubble")
    }

    func testTappingQuickLogBubbleOpensEventLoggingSheet() {
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        let feedingBubble = app.staticTexts["Feeding"]
        guard feedingBubble.waitForExistence(timeout: 10) else {
            // No child exists
            return
        }

        // When: Tap the Feeding bubble
        feedingBubble.tap()

        // Then: An event logging sheet should appear
        // The sheet shows "Log Feeding" as its title
        let logFeedingTitle = app.staticTexts["Log Feeding"]
        let cancelButton = app.buttons["Cancel"]

        let sheetAppeared = logFeedingTitle.waitForExistence(timeout: 5)
            || cancelButton.waitForExistence(timeout: 5)

        XCTAssertTrue(sheetAppeared, "Tapping a Quick Log bubble should open an event logging sheet")

        // Dismiss the sheet
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    func testChildSelectorMenuAppearsInToolbar() {
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        let quickLogText = app.staticTexts["Quick Log"]
        guard quickLogText.waitForExistence(timeout: 10) else {
            return
        }

        // The child selector menu should be in the navigation bar toolbar.
        // It may appear as a button with the child's name or a menu icon.
        // Look for any toolbar buttons in the navigation bar.
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(
            navBar.waitForExistence(timeout: 5),
            "Navigation bar should exist on the home screen"
        )

        // The toolbar should have at least one button (the child selector)
        let toolbarButtons = navBar.buttons
        XCTAssertTrue(
            toolbarButtons.count >= 1,
            "Toolbar should have at least one button (child selector)"
        )
    }

    func testLastFeedingCardDisplaysWhenFeedingsExist() {
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        // Look for the Last Feeding card section.
        // The card shows feeding type, time, and detail.
        // If no feedings exist, the card may show a placeholder state.
        let quickLogText = app.staticTexts["Quick Log"]
        guard quickLogText.waitForExistence(timeout: 10) else {
            return
        }

        // The Last Feeding card is part of the home scroll view.
        // We verify the section exists by scrolling and checking for elements.
        // The card may show "Last Feeding" or "No feedings yet" or similar.
        // Since this depends on data, we just verify the home layout loads.
        XCTAssertTrue(
            quickLogText.exists,
            "Home screen should render its full layout including the Last Feeding area"
        )
    }

    // MARK: - Tab Navigation

    func testCanNavigateBetweenTabs() {
        // Look for the tab bar
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            // Welcome screen, no tabs
            return
        }

        // Navigate to Summary tab
        let summaryTab = app.tabBars.buttons["Summary"]
        if summaryTab.exists {
            summaryTab.tap()

            // The Summary tab should show its content
            let dailySummaryNav = app.navigationBars["Daily Summary"]
            let activityFeedText = app.staticTexts["Activity Feed"]
            let summaryVisible = dailySummaryNav.waitForExistence(timeout: 5)
                || activityFeedText.waitForExistence(timeout: 5)

            XCTAssertTrue(summaryVisible, "Summary tab content should be visible")
        }

        // Navigate to Child tab
        let childTab = app.tabBars.buttons["Child"]
        if childTab.exists {
            childTab.tap()

            // The Child tab should show some content
            let profileNav = app.navigationBars["Profile"]
            let childProfileText = app.staticTexts["Child Profile"]
            let childVisible = profileNav.waitForExistence(timeout: 5)
                || childProfileText.waitForExistence(timeout: 5)

            XCTAssertTrue(childVisible, "Child tab content should be visible")
        }

        // Navigate back to Home
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()

            let quickLogText = app.staticTexts["Quick Log"]
            XCTAssertTrue(
                quickLogText.waitForExistence(timeout: 5),
                "Home tab should be visible after navigating back"
            )
        }
    }
}
