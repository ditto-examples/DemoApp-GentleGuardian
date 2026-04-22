import SwiftUI

/// Scrollable Information tab displaying app metadata, connected peers,
/// Ditto P2P explanation, privacy/legal links, and copyright.
struct InformationView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel: InformationViewModel?

    let dittoManager: any DittoManaging
    let userSettings: UserSettings

    // MARK: - Body

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            if let viewModel {
                scrollContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Information")
        .onAppear {
            if viewModel == nil {
                viewModel = InformationViewModel(
                    dittoManager: dittoManager,
                    userSettings: userSettings
                )
            }
        }
        .task {
            await viewModel?.startObservingPresence()
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showPrivacyNotice ?? false },
            set: { viewModel?.showPrivacyNotice = $0 }
        )) {
            PrivacyNoticeSheet()
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showLegalInfo ?? false },
            set: { viewModel?.showLegalInfo = $0 }
        )) {
            LegalInfoSheet()
        }
    }

    // MARK: - Scroll Content

    @ViewBuilder
    private func scrollContent(viewModel: InformationViewModel) -> some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // App & SDK version
                versionSection(viewModel: viewModel)

                // Current user + peers
                peersSection(viewModel: viewModel)

                // About Ditto P2P
                aboutDittoSection

                // Privacy & Legal
                legalSection(viewModel: viewModel)

                // Copyright
                copyrightSection
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
    }

    // MARK: - Version Section

    private func versionSection(viewModel: InformationViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("App Details")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                infoRow(label: "App Version", value: viewModel.appVersion)
                infoRow(label: "Ditto SDK Version", value: viewModel.sdkVersion)
            }
        }
    }

    // MARK: - Peers Section

    private func peersSection(viewModel: InformationViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Text("Connected Devices")
                    .font(.ggTitleMedium)
                    .foregroundStyle(colors.onSurface)

                // Current user
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(colors.primary)
                    Text(viewModel.displayName.isEmpty ? "You (name not set)" : viewModel.displayName)
                        .font(.ggBodyLarge)
                        .foregroundStyle(colors.onSurface)
                    Spacer()
                    Text("This Device")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.5))
                }

                if viewModel.remotePeers.isEmpty {
                    HStack(spacing: GGSpacing.sm) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .foregroundStyle(colors.onSurface.opacity(0.4))
                        Text("No other devices nearby")
                            .font(.ggBodyMedium)
                            .foregroundStyle(colors.onSurface.opacity(0.5))
                    }
                } else {
                    ForEach(viewModel.remotePeers) { peer in
                        HStack(spacing: GGSpacing.sm) {
                            Image(systemName: "person.circle")
                                .foregroundStyle(colors.secondary)
                            Text(peer.displayName)
                                .font(.ggBodyLarge)
                                .foregroundStyle(colors.onSurface)
                        }
                    }
                }
            }
        }
    }

    // MARK: - About Ditto Section

    private var aboutDittoSection: some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.ggTitleLarge)
                        .foregroundStyle(colors.primary)

                    Text("Peer-to-Peer Sync")
                        .font(.ggTitleMedium)
                        .foregroundStyle(colors.onSurface)
                }

                Text("This app is built to showcase Ditto's peer-to-peer technology. All data syncs directly between nearby devices over Bluetooth and local Wi-Fi — no cloud server is involved.")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))

                Text("Other caregivers who join your family using the same sync code will see your entries in real time, even without an internet connection.")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.7))

                Text("Your baby's data never leaves the mesh of devices in your family circle.")
                    .font(.ggBodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(colors.onSurface.opacity(0.8))
            }
        }
    }

    // MARK: - Legal Section

    private func legalSection(viewModel: InformationViewModel) -> some View {
        GGCard(style: .standard) {
            VStack(spacing: GGSpacing.md) {
                GGButton("Privacy Notice", variant: .secondary, icon: "hand.raised.fill") {
                    viewModel.showPrivacyNotice = true
                }

                GGButton("Legal Information", variant: .secondary, icon: "doc.text.fill") {
                    viewModel.showLegalInfo = true
                }
            }
        }
    }

    // MARK: - Copyright Section

    private var copyrightSection: some View {
        Text("\u{00A9} 2026 Ditto Live, Inc. All rights reserved.")
            .font(.ggBodySmall)
            .foregroundStyle(colors.onSurface.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.top, GGSpacing.md)
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ggBodyMedium)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            Spacer()
            Text(value)
                .font(.ggBodyMedium)
                .fontWeight(.medium)
                .foregroundStyle(colors.onSurface)
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Privacy Notice Sheet

private struct PrivacyNoticeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GGSpacing.lg) {
                    Text("Privacy Notice")
                        .font(.ggHeadlineLarge)
                        .foregroundStyle(colors.onSurface)

                    Text("Gentle Guardian is a demonstration application built by Ditto to showcase peer-to-peer synchronization technology.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("All data entered into this app — including child profiles and care events — is stored locally on your device and synced directly to other nearby devices in your family circle using Bluetooth Low Energy and local Wi-Fi.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("No data is transmitted to any cloud server or third-party service. Ditto does not collect, store, or process any personal information entered into this app.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("This is a demo application and should not be used as a primary record-keeping tool for medical or health-related information.")
                        .font(.ggBodyMedium)
                        .fontWeight(.medium)
                        .foregroundStyle(colors.onSurface.opacity(0.8))
                }
                .padding(GGSpacing.pageInsets)
            }
            .background(colors.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Legal Info Sheet

private struct LegalInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GGSpacing.lg) {
                    Text("Legal Information")
                        .font(.ggHeadlineLarge)
                        .foregroundStyle(colors.onSurface)

                    Text("Gentle Guardian is provided by Ditto Live, Inc. as a demonstration application for the Ditto peer-to-peer synchronization platform.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("This software is provided \"as is\" without warranty of any kind, express or implied. Ditto Live, Inc. shall not be liable for any damages arising from the use of this application.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("Ditto and the Ditto logo are trademarks of Ditto Live, Inc. Apple, iPhone, and iPad are trademarks of Apple Inc.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))

                    Text("For more information about Ditto's technology and licensing, visit ditto.live.")
                        .font(.ggBodyMedium)
                        .foregroundStyle(colors.onSurface.opacity(0.7))
                }
                .padding(GGSpacing.pageInsets)
            }
            .background(colors.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}

// MARK: - Previews

#Preview("Information") {
    NavigationStack {
        InformationView(
            dittoManager: DittoManager.shared,
            userSettings: UserSettings()
        )
    }
}
