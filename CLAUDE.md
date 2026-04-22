# GentleGuardian — Ditto SDK Demo App

A SwiftUI baby care tracker showcasing Ditto v5's peer-to-peer offline-first sync. Families log feeding, diaper, health, and activity events that sync across nearby devices over BLE/LAN without any cloud relay.

## Quick Start

### 1. Add Ditto credentials
Copy your credentials from [portal.ditto.live](https://portal.ditto.live) into:
```
src/GentleGuardian/Resources/ditto.plist
```
Fill in `DatabaseID` and `PlaygroundToken`. The app will `fatalError` at launch if either field is still set to the placeholder value.

### 2. Open in Xcode
Open `src/GentleGuardian.xcodeproj` directly — **not** the folder or `Package.swift`.

### 3. Select a destination and build
Choose any **iOS 26** simulator or select **My Mac** for a native macOS build. The app requires iOS 26+ / macOS 26+. Hit **Cmd+R** to build and run.

> **Device builds:** Set your Apple Developer `DEVELOPMENT_TEAM` in the GentleGuardian target's Signing & Capabilities tab. For full LAN/AWDL sync on device, also add the `com.apple.developer.networking.multicast` entitlement and update your provisioning profile.

---

## Platform Support

| Platform | Min Version | Destination |
|----------|-------------|-------------|
| iOS | 26.0 | iPhone/iPad Simulator or device |
| macOS | 26.0 | My Mac |

The app uses a single multiplatform target (native SwiftUI, **not** Mac Catalyst). Select your desired destination in Xcode's toolbar and build with Cmd+R. Platform-specific code uses `#if os(iOS)` / `#if os(macOS)` conditional compilation.

---

## Managing the Xcode Project

The Xcode project (`GentleGuardian.xcodeproj`) is managed directly — no code generation tools are needed. When adding new source files, use Xcode's Project Navigator (**File > Add Files to "GentleGuardian"**) or drag them into the project. Ensure new files are added to the **GentleGuardian** target.

---

## Project Structure

```
demoapp-babytracker/
├── CLAUDE.md               <- You are here
├── designs/
│   ├── light/              <- Light mode design spec + mockups
│   │   └── DESIGN.md       <- "Tactile Sanctuary" light palette
│   └── dark/               <- Dark mode design spec + mockups
│       └── DESIGN.md       <- "Midnight Watch" dark palette
└── src/
    ├── Package.swift       <- SPM package (for CLI builds / CI)
    ├── GentleGuardian.xcodeproj
    └── GentleGuardian/
        ├── App/            <- Entry point, ContentView, AppConstants, Info.plist
        ├── Core/
        │   ├── Ditto/      <- DittoManager actor, DittoManaging protocol
        │   ├── Models/     <- Codable structs + 18 enums
        │   ├── Repositories/ <- 6 @Observable repositories (live DQL observers)
        │   └── Services/   <- DateService, ActiveChildState, SyncCodeGenerator
        ├── DesignSystem/
        │   ├── Theme/      <- GGColors, GGTypography, GGSpacing, GGElevation
        │   ├── Components/ <- GGCard, GGButton, GGTextField, GGActivityBubble, etc.
        │   └── Modifiers/  <- NightModeModifier, SurfaceModifier, GhostBorderModifier
        ├── Features/
        │   ├── Home/       <- Dashboard: greeting, last-feeding card, quick-log grid
        │   ├── Summary/    <- Daily stats + chronological event feed
        │   ├── ChildProfile/ <- Child management, sync code display, tracking day
        │   ├── Onboarding/ <- WelcomeView, RegisterChild, JoinFamily
        │   └── EventLogging/ <- Log sheets for Feeding, Diaper, Health, Activity
        └── Resources/
            ├── ditto.plist         <- YOUR CREDENTIALS GO HERE
            └── ditto.plist.example <- Template
```

---

## Architecture

**Layers (outer -> inner):**

```
App (GentleGuardianApp)
  └── Features (Views + ViewModels)
        └── Repositories (@Observable, live DQL observers)
              └── DittoManager (actor — thread-safe SDK wrapper)
```

### Key patterns

| Pattern | Where used |
|---------|-----------|
| `@Observable` | Repositories and `ActiveChildState` — no Combine/ObservableObject |
| Actor isolation | `DittoManager` is a Swift actor; call sites use `await` |
| `@MainActor` | All repositories are `@MainActor` — safe to update SwiftUI state |
| Soft delete | All events have `isArchived: Bool`; queries filter with `QueryHelpers.notArchived` |
| Unit-agnostic storage | Measurements stored as (value, unit) pairs — never hardcode oz or ml |
| `SmallPeersOnly` sync scope | Applied to every collection via `ALTER SYSTEM SET USER_COLLECTION_SYNC_SCOPES` |

### Data flow
1. User taps a quick-log button -> `LogEventSheet` sheet appears
2. View calls ViewModel method -> ViewModel calls Repository method
3. Repository calls `DittoManager.execute(query:)` -> DQL `INSERT`
4. Ditto notifies the live observer -> Repository updates its `@Observable` published array
5. View re-renders automatically

### Sync pairing (sync codes)
- `SyncCodeGenerator` creates a 6-char alphanumeric code on child registration
- Stored in the `children` collection as `syncCode`
- A joining device calls `DittoManager.subscribeToChildBySyncCode(_:)` to discover the child, then subscribes to all event collections by `childId`

---

## Ditto SDK Notes

- **Version:** 5.0.0-rc.2+ (see `Package.swift`)
- **Swift language mode:** v5 — required because Ditto uses `[String: Any?]` which is not `Sendable`. Do not upgrade to Swift 6 mode until the SDK is updated.
- **Auth:** Online Playground identity. The `expirationHandler` in `DittoManager` re-logs in automatically using `dittoPlaygroundToken`.
- **Transports:** BLE + LAN + AWDL enabled; WebSocket disabled (P2P only, no cloud relay for event data).
- **DQL queries:** Use `QueryHelpers` for reusable filter snippets. All queries pass `arguments:` dictionaries — never interpolate user data into query strings.

---

## Adding a New Feature

1. Add model struct in `Core/Models/` with `toDittoDocument()` and `init(from:)` methods
2. Add repository in `Core/Repositories/` following the `FeedingRepository` pattern
3. Add collection name to `AppConstants.Collections` and the `all` array
4. Wire the repository into `GentleGuardianApp.init()` and pass it down via `ContentView`
5. Create Views + ViewModel in `Features/YourFeature/`
6. Add new files to the Xcode project via **File > Add Files to "GentleGuardian"** (ensure the GentleGuardian target is checked)

---

## Design System

All UI uses the `GG*` design tokens. The design specifications live in the `designs/` folder:

```
designs/
├── light/
│   ├── DESIGN.md           <- Light mode color palette, typography, elevation, components
│   ├── home.png            <- Light mode home screen mockup
│   ├── daily-summary.png   <- Light mode summary screen mockup
│   ├── child-profile.png   <- Light mode child profile mockup
│   └── add-sync-child.png  <- Light mode onboarding mockup
└── dark/
    ├── DESIGN.md           <- Dark mode color palette ("Midnight Watch" theme)
    ├── home.png            <- Dark mode home screen mockup
    ├── daily-summary.png   <- Dark mode summary screen mockup
    ├── child-profile.png   <- Dark mode child profile mockup
    └── add-sync-child.png  <- Dark mode onboarding mockup
```

- **Colors:** `GGColors` — light palette: botanical greens + aquatic blues; dark palette: deep navy surfaces + bioluminescent teal accents
- **Typography:** Plus Jakarta Sans (display + body in both modes)
- **Components:** `GGCard`, `GGButton`, `GGTextField`, `GGActivityBubble`, `GGGlassBar`
- **Light/Dark mode:** Uses system `ColorScheme` via `@Environment(\.colorScheme)`. Apply `.colorSchemeAware()` at the app root to propagate `GGAdaptiveColors` through the environment. No manual toggle — the system controls appearance.

---

## Testing

```bash
# Unit + integration tests (via SPM, no simulator needed for most)
cd src && swift test

# Or run tests in Xcode: Cmd+U
```

- Unit tests mock `DittoManaging` via `MockDittoManager` in `GentleGuardianTests/Mocks/`
- Integration tests use a real Ditto instance — they skip automatically if `ditto.plist` has placeholder credentials
- UI tests use `XCUIApplication` and require a running simulator

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `fatalError: Missing ditto.plist` | Fill in `DatabaseID` and `PlaygroundToken` in `src/GentleGuardian/Resources/ditto.plist` |
| New file not compiling | Ensure the file is added to the GentleGuardian target in Xcode's File Inspector |
| `SWIFT_VERSION` errors about Sendable | Ensure `SWIFT_VERSION = 5.0` is set in the target build settings |
| Device build fails for provisioning | Set your `DEVELOPMENT_TEAM` in Xcode Signing & Capabilities |
| LAN/AWDL sync not working on device | Add `com.apple.developer.networking.multicast` to your entitlements and update provisioning profile |
| macOS build fails with sandbox violation | Check entitlements include `network.client`, `network.server`, and `device.bluetooth` |
