import SwiftUI

/// The initial onboarding screen shown when no children have been added.
///
/// Presents two options matching the add_or_sync_child mockup:
/// - Register a New Baby (creates a new child record with a sync code)
/// - Join Family (join an existing child using a sync code from another device)
struct WelcomeView: View {

    // MARK: - Environment

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.isNightMode) private var isNightMode

    // MARK: - State

    @State private var showRegisterChild = false
    @State private var showJoinFamily = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GGGradientBackground(style: .fullScreen)

                ScrollView {
                    VStack(spacing: GGSpacing.xl) {
                        Spacer()
                            .frame(height: GGSpacing.xxxl)

                        // Header section
                        headerSection

                        // Register card
                        registerCard

                        // Join family card
                        joinFamilyCard

                        Spacer()
                            .frame(height: GGSpacing.xxl)
                    }
                    .padding(GGSpacing.pageInsets)
                }
            }
            .navigationDestination(isPresented: $showRegisterChild) {
                RegisterChildView()
            }
            .navigationDestination(isPresented: $showJoinFamily) {
                JoinFamilyView()
            }
        }
        .accessibilityIdentifier("welcome-screen")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text("Welcome home.")
                .font(.ggHeadlineLarge)
                .foregroundStyle(colors.onSurface)

            Text("Let's set up your caretaker. Register your baby or join an existing family circle.")
                .font(.ggBodyLarge)
                .foregroundStyle(colors.onSurface.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .asymmetricHorizontalPadding()
    }

    // MARK: - Register Card

    private var registerCard: some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(.ggTitleLarge)
                        .foregroundStyle(colors.primary)

                    Text("Register a New Baby")
                        .font(.ggTitleMedium)
                        .foregroundStyle(colors.onSurface)
                }

                Text("Create a profile for your little one. You'll get a unique sync code to share with family members.")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))

                GGButton("Register a New Baby", variant: .primary, icon: "plus.circle") {
                    showRegisterChild = true
                }
                .accessibilityIdentifier("register-child-button")
            }
        }
    }

    // MARK: - Join Family Card

    private var joinFamilyCard: some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "link.circle.fill")
                        .font(.ggTitleLarge)
                        .foregroundStyle(colors.secondary)

                    Text("Join Family")
                        .font(.ggTitleMedium)
                        .foregroundStyle(colors.onSurface)
                }

                Text("Already caring for an existing account? Sync with a nearby device using a 6-character code.")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))

                GGButton("Join Family", variant: .secondary, icon: "link") {
                    showJoinFamily = true
                }
                .accessibilityIdentifier("join-family-button")
            }
        }
    }

    // MARK: - Helpers

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}

// MARK: - Previews

#Preview("Welcome View") {
    WelcomeView()
        .environment(ActiveChildState())
}
