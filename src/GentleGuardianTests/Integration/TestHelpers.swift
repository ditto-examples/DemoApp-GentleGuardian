import XCTest
import Foundation
@testable import GentleGuardian

// MARK: - Test Helpers for Integration Tests

/// Utilities for creating test data and managing asynchronous test expectations.
enum TestHelpers {

    // MARK: - Credential Checks

    /// Returns true if the Ditto credentials are placeholder values.
    ///
    /// Integration tests that require a real Ditto connection should use
    /// `XCTSkipIf(TestHelpers.credentialsArePlaceholder)` in their `setUp`.
    static var credentialsArePlaceholder: Bool {
        AppConstants.hasPlaceholderCredentials
    }

    // MARK: - Test Child Factory

    /// Creates a test `Child` with deterministic values.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a UUID-based value.
    ///   - firstName: The child's first name. Defaults to "TestChild".
    ///   - syncCode: A sync code. Defaults to "TST001".
    /// - Returns: A `Child` suitable for test usage.
    static func makeTestChild(
        id: String = "test-child-\(UUID().uuidString.prefix(8))",
        firstName: String = "TestChild",
        syncCode: String = "TST001"
    ) -> Child {
        Child(
            id: id,
            firstName: firstName,
            birthday: Date(timeIntervalSince1970: 1_700_000_000),
            sex: .female,
            syncCode: syncCode,
            createdByDeviceId: "test-device"
        )
    }

    // MARK: - Test Feeding Event Factory

    /// Creates a test `FeedingEvent` with deterministic values.
    ///
    /// - Parameters:
    ///   - id: A unique identifier.
    ///   - childId: The associated child ID.
    ///   - type: The feeding type. Defaults to `.bottle`.
    ///   - date: The date string. Defaults to "2026-04-15".
    /// - Returns: A `FeedingEvent` suitable for test usage.
    static func makeTestFeedingEvent(
        id: String = "test-feed-\(UUID().uuidString.prefix(8))",
        childId: String = "test-child-1",
        type: FeedingType = .bottle,
        date: String = "2026-04-15"
    ) -> FeedingEvent {
        FeedingEvent(
            id: id,
            childId: childId,
            type: type,
            timestamp: Date(),
            date: date,
            bottleQuantity: 120.0,
            bottleQuantityUnit: .ml
        )
    }

    // MARK: - Test Diaper Event Factory

    /// Creates a test `DiaperEvent` with deterministic values.
    static func makeTestDiaperEvent(
        id: String = "test-diaper-\(UUID().uuidString.prefix(8))",
        childId: String = "test-child-1",
        type: DiaperType = .poop,
        date: String = "2026-04-15"
    ) -> DiaperEvent {
        DiaperEvent(
            id: id,
            childId: childId,
            type: type,
            timestamp: Date(),
            date: date,
            quantity: .medium,
            color: .brown,
            consistency: .solid
        )
    }

    // MARK: - Test Health Event Factory

    /// Creates a test `HealthEvent` with deterministic values.
    static func makeTestHealthEvent(
        id: String = "test-health-\(UUID().uuidString.prefix(8))",
        childId: String = "test-child-1",
        type: HealthEventType = .temperature,
        date: String = "2026-04-15"
    ) -> HealthEvent {
        HealthEvent(
            id: id,
            childId: childId,
            type: type,
            timestamp: Date(),
            date: date,
            temperatureValue: 98.6,
            temperatureUnit: .fahrenheit
        )
    }

    // MARK: - Test Activity Event Factory

    /// Creates a test `ActivityEvent` with deterministic values.
    static func makeTestActivityEvent(
        id: String = "test-activity-\(UUID().uuidString.prefix(8))",
        childId: String = "test-child-1",
        activityType: ActivityType = .bath,
        date: String = "2026-04-15"
    ) -> ActivityEvent {
        ActivityEvent(
            id: id,
            childId: childId,
            activityType: activityType,
            timestamp: Date(),
            date: date,
            durationMinutes: 30,
            description: "Test activity"
        )
    }

    // MARK: - Test Custom Item Factory

    /// Creates a test `CustomItem` with deterministic values.
    static func makeTestCustomItem(
        id: String = "test-custom-\(UUID().uuidString.prefix(8))",
        childId: String = "test-child-1",
        category: CustomItemCategory = .formula,
        name: String = "Test Formula"
    ) -> CustomItem {
        CustomItem(
            id: id,
            childId: childId,
            category: category,
            name: name,
            defaultQuantity: 120.0,
            defaultQuantityUnit: "ml"
        )
    }

    // MARK: - Unique Database Name

    /// Generates a unique database name for test isolation.
    ///
    /// Each integration test can use a unique database name to avoid
    /// collisions between parallel test runs.
    static func uniqueDatabaseName(testName: String = #function) -> String {
        "test_\(testName)_\(UUID().uuidString.prefix(8))"
    }
}

// MARK: - XCTestCase Async Helpers

extension XCTestCase {

    /// Waits for an asynchronous condition to become true, polling at regular intervals.
    ///
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds. Defaults to 5.
    ///   - pollingInterval: How often to check in nanoseconds. Defaults to 100ms.
    ///   - condition: An async closure that returns true when the condition is met.
    ///   - message: Failure message if the condition is not met within the timeout.
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        pollingInterval: UInt64 = 100_000_000,
        message: String = "Condition was not met within timeout",
        condition: @escaping () async -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() {
                return
            }
            try? await Task.sleep(nanoseconds: pollingInterval)
        }
        XCTFail(message)
    }

    /// Waits for an observer callback to fire, using an expectation pattern.
    ///
    /// - Parameters:
    ///   - description: A description for the expectation.
    ///   - timeout: Maximum time to wait in seconds. Defaults to 5.
    /// - Returns: The `XCTestExpectation` that the callback should fulfill.
    func observerExpectation(
        description: String = "Observer callback fired",
        timeout: TimeInterval = 5.0
    ) -> XCTestExpectation {
        let expectation = self.expectation(description: description)
        expectation.assertForOverFulfill = false
        return expectation
    }
}

// MARK: - MockDittoManager Test Extensions

extension MockDittoManager {

    /// Returns the number of executed queries.
    var queryCount: Int {
        get async { executedQueries.count }
    }

    /// Returns the number of registered observers.
    var observerCount: Int {
        get async { registeredObservers.count }
    }

    /// Returns all subscription keys that have been subscribed.
    var allSubscribedChildIds: [String] {
        get async { subscribedChildIds }
    }

    /// Returns all sync codes that have been subscribed.
    var allSubscribedSyncCodes: [String] {
        get async { subscribedSyncCodes }
    }

    /// Returns all child IDs that have been unsubscribed.
    var allUnsubscribedChildIds: [String] {
        get async { unsubscribedChildIds }
    }
}
