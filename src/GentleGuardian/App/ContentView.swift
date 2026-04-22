import SwiftUI

/// Root content view that decides between onboarding and the main tab interface.
///
/// - If no children exist, shows the WelcomeView for onboarding.
/// - If children exist, shows the main TabView with Home, Summary, and Child tabs.
/// - On iPad/Mac, uses NavigationSplitView with a sidebar.
struct ContentView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(UserSettings.self) private var userSettings

    // MARK: - Dependencies

    let feedingRepository: FeedingRepository
    let diaperRepository: DiaperRepository
    let healthRepository: HealthRepository
    let activityRepository: ActivityRepository
    let sleepRepository: SleepRepository
    let otherEventRepository: OtherEventRepository
    let vaccinationRepository: VaccinationRepository

    // MARK: - State

    @State private var selectedTab: AppTab = .home

    // MARK: - Body

    var body: some View {
        Group {
            if activeChildState.hasChildren {
                mainInterface
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: activeChildState.hasChildren)
    }

    // MARK: - Main Interface

    @ViewBuilder
    private var mainInterface: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
        #elseif os(macOS)
        iPadLayout
        #endif
    }

    /// Standard TabView for iPhone.
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView(
                        feedingRepository: feedingRepository,
                        diaperRepository: diaperRepository,
                        activityRepository: activityRepository,
                        healthRepository: healthRepository,
                        sleepRepository: sleepRepository,
                        otherEventRepository: otherEventRepository,
                        activeChildState: activeChildState
                    )
                }
            }
            .accessibilityIdentifier("home-tab")

            Tab("Summary", systemImage: "chart.bar.fill", value: .summary) {
                NavigationStack {
                    SummaryView(
                        feedingRepository: feedingRepository,
                        diaperRepository: diaperRepository,
                        healthRepository: healthRepository,
                        activityRepository: activityRepository,
                        sleepRepository: sleepRepository,
                        otherEventRepository: otherEventRepository,
                        activeChildState: activeChildState
                    )
                }
            }
            .accessibilityIdentifier("summary-tab")

            Tab("Child", systemImage: "person.crop.circle.fill", value: .child) {
                NavigationStack {
                    ChildProfileView()
                }
            }
            .accessibilityIdentifier("child-tab")

            if activeChildState.activeChild?.isVaccinationTrackingEnabled == true {
                Tab("Vaccines", systemImage: "syringe", value: .vaccination) {
                    NavigationStack {
                        VaccinationView(vaccinationRepository: vaccinationRepository)
                    }
                }
                .accessibilityIdentifier("vaccination-tab")
            }

            Tab("Info", systemImage: "info.circle.fill", value: .information) {
                NavigationStack {
                    InformationView(
                        dittoManager: DittoManager.shared,
                        userSettings: userSettings
                    )
                }
            }
            .accessibilityIdentifier("information-tab")
        }
    }

    /// NavigationSplitView for iPad and Mac.
    private var iPadLayout: some View {
        NavigationSplitView {
            sidebarContent(selection: Binding(
                get: { selectedTab },
                set: { selectedTab = $0 ?? .home }
            ))
        } detail: {
            switch selectedTab {
            case .home:
                HomeView(
                    feedingRepository: feedingRepository,
                    diaperRepository: diaperRepository,
                    activityRepository: activityRepository,
                    healthRepository: healthRepository,
                    sleepRepository: sleepRepository,
                    otherEventRepository: otherEventRepository,
                    activeChildState: activeChildState
                )
            case .summary:
                SummaryView(
                    feedingRepository: feedingRepository,
                    diaperRepository: diaperRepository,
                    healthRepository: healthRepository,
                    activityRepository: activityRepository,
                    sleepRepository: sleepRepository,
                    otherEventRepository: otherEventRepository,
                    activeChildState: activeChildState
                )
            case .child:
                ChildProfileView()
            case .information:
                InformationView(
                    dittoManager: DittoManager.shared,
                    userSettings: userSettings
                )
            case .vaccination:
                VaccinationView(vaccinationRepository: vaccinationRepository)
            }
        }
    }

    /// Sidebar content showing child list and tab selection.
    @ViewBuilder
    private func sidebarContent(selection: Binding<AppTab?>) -> some View {
        VStack(spacing: 0) {
            List(selection: selection) {
                Section("Navigation") {
                    Label("Home", systemImage: "house.fill")
                        .tag(AppTab.home)
                    Label("Summary", systemImage: "chart.bar.fill")
                        .tag(AppTab.summary)
                    Label("Child", systemImage: "person.crop.circle.fill")
                        .tag(AppTab.child)
                    Label("Info", systemImage: "info.circle.fill")
                        .tag(AppTab.information)
                    if activeChildState.activeChild?.isVaccinationTrackingEnabled == true {
                        Label("Vaccines", systemImage: "syringe")
                            .tag(AppTab.vaccination)
                    }
                }
            }

            if activeChildState.hasMultipleChildren {
                List {
                    Section("Children") {
                        ForEach(Array(activeChildState.children.enumerated()), id: \.element.id) { _, child in
                            Button {
                                activeChildState.selectChild(child.id)
                            } label: {
                                HStack {
                                    Text(child.firstName)
                                    Spacer()
                                    if child.id == activeChildState.activeChildId {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Gentle Guardian")
    }
}

// MARK: - App Tab

/// Tabs available in the main interface.
enum AppTab: String, Hashable {
    case home
    case summary
    case child
    case information
    case vaccination
}
