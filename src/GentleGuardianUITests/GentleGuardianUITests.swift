import XCTest

/// UI Tests for the Gentle Guardian app.
///
/// These tests verify the app's user-facing flows end-to-end.
/// Implemented in Wave 3F.
final class GentleGuardianUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // On first launch, the welcome view should be shown
        // (Detailed assertions added in Wave 3F)
    }
}
