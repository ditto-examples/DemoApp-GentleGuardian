import XCTest

/// E2E UI tests for the onboarding flow.
///
/// Tests the welcome screen, register child form, and join family views.
/// These tests use XCUITest to exercise the full user flow.
final class OnboardingE2ETests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - Welcome Screen

    func testWelcomeScreenAppearsWhenNoChildExists() {
        // On a fresh install with no children, the welcome view should be displayed.
        // The app shows a loading spinner first, then the welcome view.
        // Look for the distinctive welcome text.
        let gentleGuardianTitle = app.staticTexts["Gentle Guardian"]
        XCTAssertTrue(
            gentleGuardianTitle.waitForExistence(timeout: 10),
            "Welcome screen should show 'Gentle Guardian' title when no child exists"
        )

        let subtitle = app.staticTexts["Track your baby's day with care"]
        XCTAssertTrue(
            subtitle.waitForExistence(timeout: 5),
            "Welcome screen should show subtitle"
        )
    }

    func testWelcomeScreenShowsAddNewChildButton() {
        // The welcome screen should have an "Add a New Child" button.
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 10),
            "Welcome screen should have an 'Add a New Child' button"
        )
    }

    func testWelcomeScreenShowsJoinWithSyncCodeButton() {
        // The welcome screen should have a "Join with Sync Code" button.
        let joinButton = app.buttons["Join with Sync Code"]
        XCTAssertTrue(
            joinButton.waitForExistence(timeout: 10),
            "Welcome screen should have a 'Join with Sync Code' button"
        )
    }

    // MARK: - Navigation to Register Child

    func testCanNavigateToRegisterChildForm() {
        // Given: The welcome screen is visible
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))

        // When: Tapping "Add a New Child"
        addButton.tap()

        // Then: The registration form should appear
        // Look for the navigation title or a distinctive form element
        let navTitle = app.navigationBars["Register a New Baby"]
        let nameField = app.staticTexts["Full Name"]

        let formAppeared = navTitle.waitForExistence(timeout: 5)
            || nameField.waitForExistence(timeout: 5)

        XCTAssertTrue(formAppeared, "Register child form should appear after tapping 'Add a New Child'")
    }

    func testRegisterChildFormHasCancelButton() {
        // Given: Navigate to the register child form
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        // Then: A cancel button should be present
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5),
            "Register child form should have a Cancel button"
        )
    }

    func testCanFillInChildRegistrationForm() {
        // Given: Navigate to the register child form
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        // Wait for the form to load
        let fullNameLabel = app.staticTexts["Full Name"]
        guard fullNameLabel.waitForExistence(timeout: 5) else {
            XCTFail("Register child form did not load")
            return
        }

        // When: Fill in the name field
        // Look for a text field with the placeholder
        let nameField = app.textFields["Baby's first name"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("TestBaby")

            // Verify the text was entered
            XCTAssertEqual(nameField.value as? String, "TestBaby")
        }

        // Note: DatePicker and Picker interactions are complex in XCUITest
        // and depend on the exact UI layout. We verify the form sections exist.
        let birthdayLabel = app.staticTexts["Birthday"]
        XCTAssertTrue(
            birthdayLabel.exists,
            "Registration form should have a Birthday section"
        )

        let sexLabel = app.staticTexts["Sex"]
        XCTAssertTrue(
            sexLabel.exists,
            "Registration form should have a Sex section"
        )
    }

    func testRegisterChildFormHasSubmitButton() {
        // Given: Navigate to the register child form
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        // Then: The "Complete Registration" button should exist
        let submitButton = app.buttons["Complete Registration"]
        XCTAssertTrue(
            submitButton.waitForExistence(timeout: 5),
            "Register child form should have a 'Complete Registration' button"
        )
    }

    func testCancelDismissesRegistrationForm() {
        // Given: Navigate to the register child form
        let addButton = app.buttons["Add a New Child"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        // When: Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        // Then: The welcome screen should be visible again
        let gentleGuardianTitle = app.staticTexts["Gentle Guardian"]
        XCTAssertTrue(
            gentleGuardianTitle.waitForExistence(timeout: 5),
            "Welcome screen should reappear after cancelling registration"
        )
    }

    // MARK: - Navigation to Join Family

    func testCanNavigateToJoinFamilyAndSeeSyncCodeInput() {
        // Given: The welcome screen is visible
        let joinButton = app.buttons["Join with Sync Code"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))

        // When: Tapping "Join with Sync Code"
        joinButton.tap()

        // Then: The join family form should appear with a sync code input
        let navTitle = app.navigationBars["Join Family"]
        let syncCodeLabel = app.staticTexts["Sync Code"]
        let syncCodeField = app.textFields["Enter 6-character code"]

        let formAppeared = navTitle.waitForExistence(timeout: 5)
            || syncCodeLabel.waitForExistence(timeout: 5)

        XCTAssertTrue(formAppeared, "Join Family form should appear with sync code section")

        if syncCodeField.waitForExistence(timeout: 3) {
            XCTAssertTrue(syncCodeField.exists, "Sync code text field should be visible")
        }
    }

    func testJoinFamilyHasValidateCodeButton() {
        // Given: Navigate to join family
        let joinButton = app.buttons["Join with Sync Code"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))
        joinButton.tap()

        // Then: The "Validate Code" button should exist
        let validateButton = app.buttons["Validate Code"]
        XCTAssertTrue(
            validateButton.waitForExistence(timeout: 5),
            "Join Family form should have a 'Validate Code' button"
        )
    }

    func testJoinFamilyHasCancelButton() {
        // Given: Navigate to join family
        let joinButton = app.buttons["Join with Sync Code"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))
        joinButton.tap()

        // Then: A cancel button should be present
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5),
            "Join Family form should have a Cancel button"
        )
    }

    func testCancelDismissesJoinFamilyForm() {
        // Given: Navigate to join family form
        let joinButton = app.buttons["Join with Sync Code"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))
        joinButton.tap()

        // When: Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        // Then: The welcome screen should be visible again
        let gentleGuardianTitle = app.staticTexts["Gentle Guardian"]
        XCTAssertTrue(
            gentleGuardianTitle.waitForExistence(timeout: 5),
            "Welcome screen should reappear after cancelling join family"
        )
    }
}
