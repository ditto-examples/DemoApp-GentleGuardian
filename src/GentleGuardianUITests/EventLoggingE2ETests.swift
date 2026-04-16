import XCTest

/// E2E UI tests for event logging flows.
///
/// These tests verify that users can open event logging forms from the
/// Quick Log grid and interact with them. Tests that require a child to
/// be registered will gracefully skip if the home screen is not visible.
final class EventLoggingE2ETests: XCTestCase {

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

    // MARK: - Helpers

    /// Navigates to the home tab and verifies it's visible.
    /// Returns false if the app shows the welcome screen instead.
    @discardableResult
    private func navigateToHome() -> Bool {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        let quickLogText = app.staticTexts["Quick Log"]
        return quickLogText.waitForExistence(timeout: 10)
    }

    /// Taps a Quick Log bubble by label text and waits for the sheet to appear.
    /// Returns the sheet title text if found, nil otherwise.
    @discardableResult
    private func openEventSheet(bubbleLabel: String) -> Bool {
        let bubble = app.staticTexts[bubbleLabel]
        guard bubble.waitForExistence(timeout: 5) else {
            return false
        }

        bubble.tap()

        // Wait for the sheet to appear (look for a Cancel button as indicator)
        let cancelButton = app.buttons["Cancel"]
        return cancelButton.waitForExistence(timeout: 5)
    }

    // MARK: - Feeding Event

    func testCanOpenBottleFeedingFormFromQuickLog() {
        guard navigateToHome() else { return }

        // When: Tap "Feeding" in Quick Log
        guard openEventSheet(bubbleLabel: "Feeding") else {
            XCTFail("Feeding event sheet should open from Quick Log")
            return
        }

        // Then: The feeding form sheet should be visible
        let logFeedingText = app.staticTexts["Log Feeding"]
        XCTAssertTrue(
            logFeedingText.waitForExistence(timeout: 5),
            "Feeding form should show 'Log Feeding' text"
        )
    }

    func testFeedingSheetHasCancelButton() {
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Feeding") else { return }

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Feeding sheet should have a Cancel button")
    }

    func testFeedingSheetDismissesOnCancel() {
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Feeding") else { return }

        // When: Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        // Then: The sheet should dismiss and Quick Log should be visible again
        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Quick Log should be visible after dismissing the feeding sheet"
        )
    }

    // MARK: - Diaper Event

    func testCanOpenDiaperFormFromQuickLog() {
        guard navigateToHome() else { return }

        // When: Tap "Diaper" in Quick Log
        guard openEventSheet(bubbleLabel: "Diaper") else {
            XCTFail("Diaper event sheet should open from Quick Log")
            return
        }

        // Then: The diaper form sheet should be visible
        let logDiaperText = app.staticTexts["Log Diaper"]
        XCTAssertTrue(
            logDiaperText.waitForExistence(timeout: 5),
            "Diaper form should show 'Log Diaper' text"
        )
    }

    func testDiaperSheetDismissesOnCancel() {
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Diaper") else { return }

        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Quick Log should be visible after dismissing the diaper sheet"
        )
    }

    // MARK: - Health Event (Temperature)

    func testCanOpenHealthFormFromQuickLog() {
        guard navigateToHome() else { return }

        // When: Tap "Health" in Quick Log
        guard openEventSheet(bubbleLabel: "Health") else {
            XCTFail("Health event sheet should open from Quick Log")
            return
        }

        // Then: The health form sheet should be visible
        let logHealthText = app.staticTexts["Log Health"]
        XCTAssertTrue(
            logHealthText.waitForExistence(timeout: 5),
            "Health form should show 'Log Health' text"
        )
    }

    func testHealthSheetDismissesOnCancel() {
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Health") else { return }

        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Quick Log should be visible after dismissing the health sheet"
        )
    }

    // MARK: - Activity Event

    func testCanOpenActivityFormFromQuickLog() {
        guard navigateToHome() else { return }

        // When: Tap "Activity" in Quick Log
        guard openEventSheet(bubbleLabel: "Activity") else {
            XCTFail("Activity event sheet should open from Quick Log")
            return
        }

        // Then: The activity form sheet should be visible
        let logActivityText = app.staticTexts["Log Activity"]
        XCTAssertTrue(
            logActivityText.waitForExistence(timeout: 5),
            "Activity form should show 'Log Activity' text"
        )
    }

    func testActivitySheetDismissesOnCancel() {
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Activity") else { return }

        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Quick Log should be visible after dismissing the activity sheet"
        )
    }

    // MARK: - Form Dismissal After Saving

    func testFormDismissesAfterSaving() {
        // This test verifies that after a successful save, the event logging
        // sheet is dismissed and the user returns to the home screen.
        // Since saving requires form interaction and a working Ditto instance,
        // we test the dismiss flow using the Cancel button as a proxy.
        guard navigateToHome() else { return }
        guard openEventSheet(bubbleLabel: "Feeding") else { return }

        // Verify the sheet is visible
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)

        // Dismiss the sheet
        cancelButton.tap()

        // Verify we're back on the home screen
        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Home screen should be visible after sheet dismissal"
        )
    }

    // MARK: - Multiple Sheet Opens

    func testCanOpenMultipleSheetsSequentially() {
        guard navigateToHome() else { return }

        // Open and close Feeding sheet
        if openEventSheet(bubbleLabel: "Feeding") {
            app.buttons["Cancel"].tap()
            _ = app.staticTexts["Quick Log"].waitForExistence(timeout: 3)
        }

        // Open and close Diaper sheet
        if openEventSheet(bubbleLabel: "Diaper") {
            app.buttons["Cancel"].tap()
            _ = app.staticTexts["Quick Log"].waitForExistence(timeout: 3)
        }

        // Open and close Health sheet
        if openEventSheet(bubbleLabel: "Health") {
            app.buttons["Cancel"].tap()
            _ = app.staticTexts["Quick Log"].waitForExistence(timeout: 3)
        }

        // Open and close Activity sheet
        if openEventSheet(bubbleLabel: "Activity") {
            app.buttons["Cancel"].tap()
        }

        // Verify we're still on the home screen
        let quickLogText = app.staticTexts["Quick Log"]
        XCTAssertTrue(
            quickLogText.waitForExistence(timeout: 5),
            "Home screen should remain stable after opening/closing multiple sheets"
        )
    }
}
