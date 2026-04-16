import SwiftUI
import DittoSwift

/// Main entry point for the Gentle Guardian baby tracker app.
@main
struct GentleGuardianApp: App {

    // MARK: - State

    /// The shared Ditto manager actor responsible for all database operations.
    private let dittoManager = DittoManager.shared

    /// Observable state tracking the active child and all children.
    @State private var activeChildState = ActiveChildState()

    /// Repositories for event data, created once and shared across the app.
    @State private var feedingRepository: FeedingRepository
    @State private var diaperRepository: DiaperRepository
    @State private var healthRepository: HealthRepository
    @State private var activityRepository: ActivityRepository

    /// Tracks whether Ditto initialization has completed.
    @State private var isInitialized = false

    /// Tracks any initialization error for display.
    @State private var initError: String?

    // MARK: - Initialization

    init() {
        let manager = DittoManager.shared
        _feedingRepository = State(initialValue: FeedingRepository(dittoManager: manager))
        _diaperRepository = State(initialValue: DiaperRepository(dittoManager: manager))
        _healthRepository = State(initialValue: HealthRepository(dittoManager: manager))
        _activityRepository = State(initialValue: ActivityRepository(dittoManager: manager))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if let initError {
                    InitializationErrorView(error: initError) {
                        self.initError = nil
                        Task {
                            await initializeDitto()
                        }
                    }
                } else if !isInitialized {
                    ProgressView("Starting Gentle Guardian...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentView(
                        feedingRepository: feedingRepository,
                        diaperRepository: diaperRepository,
                        healthRepository: healthRepository,
                        activityRepository: activityRepository
                    )
                }
            }
            .environment(activeChildState)
            .task {
                await initializeDitto()
            }
        }
    }

    // MARK: - Private Methods

    /// Initializes Ditto and loads the initial child list.
    private func initializeDitto() async {
        do {
            try await dittoManager.initialize()
            await loadChildren()
            isInitialized = true
        } catch {
            initError = error.localizedDescription
        }
    }

    /// Loads the initial children from the local Ditto store.
    private func loadChildren() async {
        do {
            let result = try await dittoManager.execute(
                query: "SELECT * FROM \(AppConstants.Collections.children) WHERE \(QueryHelpers.notArchived) ORDER BY firstName ASC",
                arguments: [:]
            )

            let children = result.items.map { item in
                let doc = item.value
                let child = Child(from: doc)
                item.dematerialize()
                return child
            }

            activeChildState.updateChildren(children)
        } catch {
            // On first launch there will be no children; this is expected.
        }
    }
}

// MARK: - Initialization Error View

/// Displayed when Ditto initialization fails, with a retry option.
private struct InitializationErrorView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Unable to Start")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
