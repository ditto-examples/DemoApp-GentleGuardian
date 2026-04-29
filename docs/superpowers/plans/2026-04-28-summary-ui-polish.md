# Summary Tab UI Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten the Summary tab UI — remove redundant section titles, swap the Food Ranking filter to a wheel on iPhone and a menu on iPad/macOS, hide picker labels and shrink date-nav buttons on macOS — without changing any data-layer behavior.

**Architecture:** All changes are confined to two SwiftUI view files (`SummaryView.swift`, `FoodRankingList.swift`) plus one new render-smoke unit-test file. Platform branches use `#if os(macOS)` and a runtime check on `UIDevice.current.userInterfaceIdiom` to pick the iPhone wheel vs iPad menu picker style. No public APIs change.

**Tech Stack:** SwiftUI (iOS 26 / macOS 26), Swift Testing (`@Suite` / `@Test`), Xcode-only test runner (DittoSwift binary framework signature requires it), manually-edited `project.pbxproj`.

---

## File Structure

**Modify:**
- `src/GentleGuardian/Features/Summary/Views/SummaryView.swift`
  - Remove `Text("Activity Feed")` from `dateNavigationRow`.
  - Remove `Text("Growth")` from `growthSection`.
  - Remove `Text("Food Ranking")` from `foodRankingSection`.
  - Add `.labelsHidden()` and centering wrapper to `sectionPicker`.
  - Add `summaryDateButtonStyle()` private extension and apply to chevrons.
- `src/GentleGuardian/Features/Summary/Views/FoodRankingList.swift`
  - Add `.labelsHidden()` to `filterPicker`.
  - Branch on platform/idiom: wheel on iPhone, menu on iPad/macOS.

**Create:**
- `src/GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift`
  - Render-smoke `@Test`s that host `FoodRankingList` for each `FoodRankingFilter` value and confirm the body evaluates without crashing.

**Modify (mechanical):**
- `src/GentleGuardian.xcodeproj/project.pbxproj` — register the new test file.

---

## Task 1: Add render-smoke test scaffold

**Files:**
- Create: `src/GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift`
- Modify: `src/GentleGuardian.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create the test directory if it does not exist**

```bash
mkdir -p src/GentleGuardianTests/Unit/Views
```

- [ ] **Step 2: Write the failing test file**

Create `src/GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift`:

```swift
import Testing
import SwiftUI
@testable import GentleGuardian

#if os(iOS)
import UIKit
typealias HostController = UIHostingController<AnyView>
#elseif os(macOS)
import AppKit
typealias HostController = NSHostingController<AnyView>
#endif

/// Render-smoke tests for the Summary tab's stand-alone list views.
///
/// These do not assert on layout — they instantiate the view inside a host
/// controller, which forces SwiftUI to evaluate `body` and apply view
/// modifiers. If a recent change introduces a compile-time platform branch
/// that fails to compile, or a runtime crash inside `body`, these catch it.
@Suite("Summary Layout Render Smoke")
@MainActor
struct SummaryViewLayoutTests {

    @Test("FoodRankingList renders empty state for each filter")
    func foodRankingEmptyForEachFilter() {
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: [])
            _ = renderHost(view)
        }
    }

    @Test("FoodRankingList renders populated state for each filter")
    func foodRankingPopulatedForEachFilter() {
        let summaries: [FoodReactionSummary] = [
            FoodReactionSummary(
                foodName: "Avocado",
                totalCount: 3,
                happyCount: 2,
                neutralCount: 1,
                frownCount: 0
            ),
            FoodReactionSummary(
                foodName: "Broccoli",
                totalCount: 2,
                happyCount: 0,
                neutralCount: 0,
                frownCount: 2
            )
        ]
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: summaries)
            _ = renderHost(view)
        }
    }

    // MARK: - Host helper

    /// Wraps the SwiftUI view in a platform-appropriate hosting controller and
    /// forces a layout pass so SwiftUI evaluates `body`. The returned object
    /// is intentionally discarded — the side effect of body evaluation is
    /// what matters.
    private func renderHost<V: View>(_ view: V) -> HostController {
        let host = HostController(rootView: AnyView(view))
        #if os(iOS)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
        #elseif os(macOS)
        host.view.frame = NSRect(x: 0, y: 0, width: 600, height: 800)
        host.view.layoutSubtreeIfNeeded()
        #endif
        return host
    }
}
```

- [ ] **Step 3: Register the new file in `project.pbxproj`**

Read the current pbxproj to locate the unit-test Sources phase and the tests group, then add three entries (PBXFileReference, PBXBuildFile, Sources phase entry). Use this exact pattern that was used for `FoodReactionAggregatorTests.swift` in a prior commit — manually-coined hex IDs `AA01F00D000000000000002A`–`AA01F00E000000000000002A`.

The three additions:

a. **PBXBuildFile entry** (new identifier `AA01F00E000000000000003A`) in the build-file section:

```
		AA01F00E000000000000003A /* SummaryViewLayoutTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA01F00D000000000000003A /* SummaryViewLayoutTests.swift */; };
```

Insert immediately after the `FoodReactionAggregatorTests.swift in Sources` PBXBuildFile entry (locate via `grep -n "FoodReactionAggregatorTests.swift in Sources" src/GentleGuardian.xcodeproj/project.pbxproj`).

b. **PBXFileReference entry** (new identifier `AA01F00D000000000000003A`):

```
		AA01F00D000000000000003A /* SummaryViewLayoutTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SummaryViewLayoutTests.swift; sourceTree = "<group>"; };
```

Insert immediately after the `FoodReactionAggregatorTests.swift` PBXFileReference entry.

c. **Sources phase entry** for the test target — find the `GentleGuardianTests` PBXSourcesBuildPhase and add the build-file UUID `AA01F00E000000000000003A` next to the `FoodReactionAggregatorTests.swift in Sources` entry inside the `files = (...);` array.

d. **Group children** — find the test target's `Unit` group children list. If a `Views` subgroup exists under `Unit`, add the file ref into it; otherwise add a new PBXGroup for `Views` and put the new file in it. The simpler path: add to the existing `Unit/Services` parent group's siblings (the same group where `FoodReactionAggregatorTests` lives works fine — Xcode does not enforce on-disk path matching).

The simplest approach: open `project.pbxproj` and copy the four `FoodReactionAggregatorTests` entry blocks into the same locations, replacing the name and the IDs. The new IDs MUST NOT collide with any existing 24-char hex ID in the file.

- [ ] **Step 4: Build the test target via Xcode to verify the file is registered**

Use the Xcode MCP tool:

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

Expected: build succeeds. If you see "Cannot find type 'FoodReactionSummary' in scope" or "no such file or directory", the pbxproj is malformed — re-check Steps 3a-3d.

- [ ] **Step 5: Run the test once to confirm it passes against the current code**

```
mcp__xcode__RunAllTests(tabIdentifier: "windowtab2")
```

Expected: 350+ tests pass, including 2 new `SummaryViewLayoutTests`. The 14 pre-existing `GentleGuardianUITests` failures (unrelated XCUITest E2E flakiness) are expected and ignored.

- [ ] **Step 6: Commit**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian
git add src/GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift \
        src/GentleGuardian.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
test(summary): add render-smoke tests for FoodRankingList

Hosts FoodRankingList in a platform-appropriate hosting controller and
forces a layout pass for each FoodRankingFilter value. Catches future
regressions when the picker style is platform-branched.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Switch FoodRankingList filter to platform-adaptive picker

**Files:**
- Modify: `src/GentleGuardian/Features/Summary/Views/FoodRankingList.swift:35-43`

- [ ] **Step 1: Replace the body of `filterPicker`**

Open `src/GentleGuardian/Features/Summary/Views/FoodRankingList.swift`. Replace this block:

```swift
    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(FoodRankingFilter.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("food-ranking-filter")
    }
```

with:

```swift
    @ViewBuilder
    private var filterPicker: some View {
        let picker = Picker("Filter", selection: $filter) {
            ForEach(FoodRankingFilter.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .labelsHidden()
        .accessibilityIdentifier("food-ranking-filter")

        #if os(macOS)
        HStack {
            Spacer()
            picker.pickerStyle(.menu).frame(maxWidth: 200)
        }
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            HStack {
                Spacer()
                picker.pickerStyle(.menu).frame(maxWidth: 200)
            }
        } else {
            picker.pickerStyle(.wheel).frame(height: 120)
        }
        #endif
    }
```

- [ ] **Step 2: Build to confirm both platforms compile**

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

Expected: build succeeds (iOS simulator destination by default).

Then verify macOS builds via xcodebuild:

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src
xcodebuild -project GentleGuardian.xcodeproj \
           -scheme GentleGuardian \
           -destination 'platform=macOS' \
           -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run all tests via Xcode**

```
mcp__xcode__RunAllTests(tabIdentifier: "windowtab2")
```

Expected: same pass rate as before (348 unit + 2 new = 350 unit-test passes, 14 unrelated UITest failures).

- [ ] **Step 4: Commit**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian
git add src/GentleGuardian/Features/Summary/Views/FoodRankingList.swift
git commit -m "$(cat <<'EOF'
feat(summary): platform-adaptive Food Ranking filter picker

Wheel picker on iPhone, dropdown menu on iPad and macOS. Removes the
visually-stacked-segmented-controls problem where the inner filter
mirrored the outer section picker style.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Center and label-hide the section picker

**Files:**
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift:111-120`

- [ ] **Step 1: Replace `sectionPicker`**

Open `src/GentleGuardian/Features/Summary/Views/SummaryView.swift`. Replace this block:

```swift
    private var sectionPicker: some View {
        Picker("Section", selection: $viewModel.selectedSection) {
            ForEach(SummarySection.allCases) { section in
                Text(section.displayName).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .pageHorizontalPadding()
        .accessibilityIdentifier("summary-section-picker")
    }
```

with:

```swift
    private var sectionPicker: some View {
        HStack {
            Spacer(minLength: 0)
            Picker("Section", selection: $viewModel.selectedSection) {
                ForEach(SummarySection.allCases) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .accessibilityIdentifier("summary-section-picker")
            Spacer(minLength: 0)
        }
        .pageHorizontalPadding()
    }
```

- [ ] **Step 2: Build for iOS via MCP**

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

Expected: build succeeds.

- [ ] **Step 3: Build for macOS**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src
xcodebuild -project GentleGuardian.xcodeproj \
           -scheme GentleGuardian \
           -destination 'platform=macOS' \
           -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian
git add src/GentleGuardian/Features/Summary/Views/SummaryView.swift
git commit -m "$(cat <<'EOF'
feat(summary): center section picker and hide platform label

Wraps the segmented picker in HStack/Spacer with maxWidth 420 so it
centers on macOS without stretching, and adds .labelsHidden() so the
platform-rendered "Section:" label disappears on macOS.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Compact macOS date-nav button style

**Files:**
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift:149-187,267-end`

- [ ] **Step 1: Add the `summaryDateButtonStyle()` private extension at the bottom of the file**

Append to `src/GentleGuardian/Features/Summary/Views/SummaryView.swift` (after the closing `}` of `struct SummaryView`):

```swift
private extension View {
    /// Sizes a date-navigation button.
    /// macOS: borderless 28×28 chrome.
    /// iOS: a 44×44 minimum touch target so taps never miss.
    @ViewBuilder
    func summaryDateButtonStyle() -> some View {
        #if os(macOS)
        self.buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        #else
        self.frame(
            minWidth: GGSpacing.minimumTouchTarget,
            minHeight: GGSpacing.minimumTouchTarget
        )
        #endif
    }
}
```

- [ ] **Step 2: Apply the style to both date-nav buttons in `dateNavigationRow`**

Inside `dateNavigationRow`, replace the two existing `.frame(minWidth: GGSpacing.minimumTouchTarget, minHeight: GGSpacing.minimumTouchTarget)` modifiers (one on each `Button`) with `.summaryDateButtonStyle()`.

The two affected fragments before:

```swift
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.primary)
                        .frame(minWidth: GGSpacing.minimumTouchTarget, minHeight: GGSpacing.minimumTouchTarget)
                }
```

after:

```swift
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.primary)
                }
                .summaryDateButtonStyle()
```

And similarly for the next-day button:

```swift
                Button {
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.ggLabelLarge)
                        .foregroundStyle(
                            viewModel.canGoForward
                                ? colors.primary
                                : colors.onSurfaceVariant.opacity(0.3)
                        )
                }
                .summaryDateButtonStyle()
                .disabled(!viewModel.canGoForward)
```

The `.disabled(...)` order is preserved AFTER `.summaryDateButtonStyle()` to keep the disabled tap behavior identical.

- [ ] **Step 3: Build for iOS and macOS**

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src
xcodebuild -project GentleGuardian.xcodeproj \
           -scheme GentleGuardian \
           -destination 'platform=macOS' \
           -configuration Debug build 2>&1 | tail -5
```

Expected: both succeed.

- [ ] **Step 4: Commit**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian
git add src/GentleGuardian/Features/Summary/Views/SummaryView.swift
git commit -m "$(cat <<'EOF'
feat(summary): compact macOS date-nav buttons via summaryDateButtonStyle

Borderless 28x28 chrome on macOS, 44x44 touch target preserved on iOS.
Replaces the inline frame-min modifier on each chevron button.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Remove redundant section titles

**Files:**
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift:149-187` (Activity Feed)
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift:191-203` (Growth)
- Modify: `src/GentleGuardian/Features/Summary/Views/SummaryView.swift:207-220` (Food Ranking)

- [ ] **Step 1: Strip the title and leading Spacer from `dateNavigationRow`**

Replace the current `dateNavigationRow` body:

```swift
    private var dateNavigationRow: some View {
        HStack {
            Text("Activity Feed")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)

            Spacer()

            HStack(spacing: GGSpacing.md) {
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.primary)
                }
                .summaryDateButtonStyle()

                Text(viewModel.isToday ? "Today" : viewModel.selectedDateDisplay)
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Button {
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.ggLabelLarge)
                        .foregroundStyle(
                            viewModel.canGoForward
                                ? colors.primary
                                : colors.onSurfaceVariant.opacity(0.3)
                        )
                }
                .summaryDateButtonStyle()
                .disabled(!viewModel.canGoForward)
            }
        }
        .asymmetricHorizontalPadding()
    }
```

with:

```swift
    private var dateNavigationRow: some View {
        HStack(spacing: GGSpacing.md) {
            Spacer()

            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.primary)
            }
            .summaryDateButtonStyle()

            Text(viewModel.isToday ? "Today" : viewModel.selectedDateDisplay)
                .font(.ggLabelLarge)
                .foregroundStyle(colors.onSurface)

            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.ggLabelLarge)
                    .foregroundStyle(
                        viewModel.canGoForward
                            ? colors.primary
                            : colors.onSurfaceVariant.opacity(0.3)
                    )
            }
            .summaryDateButtonStyle()
            .disabled(!viewModel.canGoForward)
        }
        .asymmetricHorizontalPadding()
    }
```

The redundant `Text("Activity Feed")` is removed, the outer wrapper-HStack collapses into one HStack with a leading `Spacer` so the chevron-date-chevron triple is right-aligned.

- [ ] **Step 2: Strip the title from `growthSection`**

Replace:

```swift
    private var growthSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
            Text("Growth")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)
                .asymmetricHorizontalPadding()

            GrowthList(events: viewModel.growthEvents) { event in
                selectedGrowthEvent = event
            }
            .pageHorizontalPadding()
        }
    }
```

with:

```swift
    private var growthSection: some View {
        GrowthList(events: viewModel.growthEvents) { event in
            selectedGrowthEvent = event
        }
        .pageHorizontalPadding()
    }
```

- [ ] **Step 3: Strip the title from `foodRankingSection`**

Replace:

```swift
    private var foodRankingSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sectionGap) {
            Text("Food Ranking")
                .font(.ggTitleLarge)
                .foregroundStyle(colors.onSurface)
                .asymmetricHorizontalPadding()

            FoodRankingList(
                filter: $viewModel.foodRankingFilter,
                summaries: viewModel.filteredFoodSummaries
            )
            .pageHorizontalPadding()
        }
    }
```

with:

```swift
    private var foodRankingSection: some View {
        FoodRankingList(
            filter: $viewModel.foodRankingFilter,
            summaries: viewModel.filteredFoodSummaries
        )
        .pageHorizontalPadding()
    }
```

- [ ] **Step 4: Build for iOS and macOS**

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src
xcodebuild -project GentleGuardian.xcodeproj \
           -scheme GentleGuardian \
           -destination 'platform=macOS' \
           -configuration Debug build 2>&1 | tail -5
```

Expected: both succeed, no new warnings (the 3 pre-existing warnings in `DittoManager.swift fetchAttachment` continue to exist and are out of scope).

- [ ] **Step 5: Run all tests via Xcode**

```
mcp__xcode__RunAllTests(tabIdentifier: "windowtab2")
```

Expected: 350+ unit tests pass (including 2 new `SummaryViewLayoutTests`), 14 unrelated `GentleGuardianUITests` failures.

- [ ] **Step 6: Commit**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian
git add src/GentleGuardian/Features/Summary/Views/SummaryView.swift
git commit -m "$(cat <<'EOF'
feat(summary): remove redundant section titles below segmented picker

The segmented control already shows the active section name. Removing
the duplicate Title in each sub-section tightens the layout on iPhone
and reduces clutter on macOS.

Activity Feed: collapsed dateNavigationRow into a right-aligned chevron
/ date / chevron HStack, dropping the redundant heading.
Growth and Food Ranking: their VStack wrappers and titles are gone;
the list views are the section's only content.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Final verification

- [ ] **Step 1: Build for iOS via MCP**

```
mcp__xcode__BuildProject(tabIdentifier: "windowtab2")
```

Expected: `The project built successfully` with no new warnings beyond the 3 pre-existing in `DittoManager.swift fetchAttachment`.

- [ ] **Step 2: Build for macOS**

```bash
cd /Users/labeaaa/Developer/DemoApp-GentleGuardian/src
xcodebuild -project GentleGuardian.xcodeproj \
           -scheme GentleGuardian \
           -destination 'platform=macOS' \
           -configuration Debug build 2>&1 | grep -E "(BUILD|warning:)" | head -20
```

Expected: `** BUILD SUCCEEDED **`. No warnings in our source tree.

- [ ] **Step 3: Run all tests via Xcode**

```
mcp__xcode__RunAllTests(tabIdentifier: "windowtab2")
```

Expected:
- 350+ tests in `GentleGuardianTests` pass.
- 14 tests in `GentleGuardianUITests` may fail — those are pre-existing simulator-state E2E flakiness (Onboarding/Home/EventLogging UI) untouched by this work.

- [ ] **Step 4: Visual spot-check via simulator (optional, manual)**

Boot any iOS 26 simulator, run the app, navigate to Summary. Confirm:
- No `Activity Feed` heading below the segmented control.
- Tap Growth — no `Growth` heading below the picker.
- Tap Food Ranking — no `Food Ranking` heading; filter renders as a wheel covering ~120pt of vertical space.
- Boot My Mac, run the app. Section picker centered, no `Section:` label, max 420pt wide. Date-nav chevrons are 28×28 borderless. Food Ranking filter is a dropdown with no `Filter:` label.

This step is a sanity check — failure here is a regression and should be debugged via standard SwiftUI debugging (check Active scheme, Derived Data) before declaring the work done.

- [ ] **Step 5: No commit needed for verification**

If any verification fails, return to the relevant task and re-run its steps.

---

## Acceptance Criteria

- [x] All five spec issues addressed (redundant titles removed, Food Ranking filter is platform-adaptive, macOS section picker centered without label, macOS date-nav buttons compact, macOS Food Ranking filter without label).
- [x] iOS Xcode build succeeds with no new warnings.
- [x] macOS xcodebuild succeeds with no new warnings.
- [x] All existing unit tests still pass.
- [x] Two new render-smoke tests pass on the iOS simulator.
- [x] No changes to public types (`SummaryViewModel`, `FoodRankingFilter`, `FoodReactionAggregator`, repositories).

## Out of scope

- Liquid Glass adoption.
- Wheel-picker tint customization.
- Replacing `UIDevice.userInterfaceIdiom` with horizontal-size-class environment reads.
- Resolving the 14 pre-existing `GentleGuardianUITests` E2E failures.
