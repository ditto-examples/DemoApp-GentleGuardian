# Summary Tab UI Polish — Design

**Date:** 2026-04-28
**Status:** Approved
**Scope:** SwiftUI Summary tab refinement on iPhone, iPad, and macOS

## Background

The Summary tab was recently redesigned to use a segmented `Picker` switching between three sub-sections: Activity Feed (default), Growth, and Food Ranking. Visual review on iPhone and macOS surfaced five concrete issues that hurt density and platform-feel:

1. The section name appears twice on every sub-view — once as the segmented control's selected segment, once as a large title below it.
2. The Food Ranking section stacks two segmented controls (the section picker and an inner All/Liked/Hated filter), which reads as visually cluttered.
3. On macOS the section picker renders with a `Section:` label, is left-anchored, and stretches the full content width.
4. On macOS the date-navigation chevrons render with default button chrome and look oversized relative to surrounding content.
5. On macOS the Food Ranking filter renders with a `Filter` label that adds clutter without information.

## Goals

- Remove redundant chrome that duplicates the segmented control's selected segment.
- Replace the stacked filter with a single platform-idiomatic control: wheel on iPhone, dropdown menu on iPad and macOS.
- Tighten macOS chrome: hide picker labels, center and width-bound the section picker, shrink the date-nav chevrons.
- Keep iOS phone behaviour close to today's layout (no regressions in touch targets).
- Preserve unit-test coverage; do not add UI tests for this work.

## Non-goals

- No changes to the underlying data model, repositories, or view-model API.
- No new sections or filters in Food Ranking.
- No accessibility-identifier renames; existing identifiers (`summary-section-picker`, `food-ranking-filter`) are preserved for downstream tests.
- No iPad-specific layout work beyond picking the dropdown style for the Food Ranking filter.

## Affected files

- `src/GentleGuardian/Features/Summary/Views/SummaryView.swift`
- `src/GentleGuardian/Features/Summary/Views/FoodRankingList.swift`
- `src/GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift` *(new)*
- `src/GentleGuardian.xcodeproj/project.pbxproj` *(register the new test file)*

No public API changes to `SummaryViewModel`, `FoodReactionAggregator`, or any repository.

## Design

### 1. Remove redundant section titles

`SummaryView` currently renders, per section:

- `dateNavigationRow` includes `Text("Activity Feed")` + `Spacer()` + chevron / date / chevron HStack.
- `growthSection` prepends `Text("Growth")` above `GrowthList`.
- `foodRankingSection` prepends `Text("Food Ranking")` above `FoodRankingList`.

These titles always match the active segment label; remove them.

The Activity Feed date row collapses to a right-aligned chevron / date / chevron control, keeping the existing `goToPreviousDay` / `goToNextDay` bindings:

```
                                   ‹  Today  ›
```

`growthSection` and `foodRankingSection` simply drop their leading `Text` views; the list view becomes the first child.

### 2. Food Ranking filter — platform-adaptive picker

`FoodRankingList.filterPicker` currently uses `.pickerStyle(.segmented)` which competes visually with the outer section segmented control. Replace with:

- **iPhone (`UIDevice.current.userInterfaceIdiom == .phone`):** `.pickerStyle(.wheel)` with a `frame(height: 120)`. A wheel surfaces all three values at once and feels native to the phone for short, mutually-exclusive filter lists.
- **iPad and macOS:** `.pickerStyle(.menu)` with `frame(maxWidth: 200)`. A dropdown is the dense, idiomatic choice on larger surfaces and avoids stealing vertical space.

The picker's `Picker("Filter", selection:)` label is hidden on every platform via `.labelsHidden()` so macOS no longer renders the `Filter` text. Default selection remains `.all` (set in the ViewModel; unchanged).

The compile-time branch lives inside `FoodRankingList.filterPicker` and is the only `#if os(macOS)` in this file.

### 3. Section picker — labelsHidden, centered, width-bounded

`SummaryView.sectionPicker` is changed to:

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

`labelsHidden()` removes `Section:` on macOS. The `Spacer` / `frame(maxWidth:)` pair centers the segmented control on macOS without affecting iPhone (where `pageHorizontalPadding` already constrains the width below 420pt on standard widths).

### 4. macOS date-nav buttons — plain style, smaller frame

A new `summaryDateButtonStyle` view extension colocated with `SummaryView`:

```swift
private extension View {
    func summaryDateButtonStyle() -> some View {
        #if os(macOS)
        return AnyView(self.buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle()))
        #else
        return AnyView(self.frame(
            minWidth: GGSpacing.minimumTouchTarget,
            minHeight: GGSpacing.minimumTouchTarget
        ))
        #endif
    }
}
```

The two `Button` instances inside `dateNavigationRow` apply `.summaryDateButtonStyle()` instead of repeating the inline `.frame(minWidth:minHeight:)` modifier. iPhone retains the 44pt minimum touch target; macOS shrinks to 28×28 with `.plain` button chrome.

### 5. Tests — unit-level only

A new test file `GentleGuardianTests/Unit/Views/SummaryViewLayoutTests.swift` exercises render-smoke for the rewired `FoodRankingList`:

```swift
@Suite("FoodRankingList Render Smoke")
@MainActor
struct SummaryViewLayoutTests {

    @Test("Renders empty state without crashing for each filter")
    func emptyStateAllFilters() {
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: [])
            // Hosting in a UIHostingController/NSHostingController forces SwiftUI
            // to evaluate the body. If the new picker style mis-fires, this
            // throws or asserts.
            _ = renderHost(view)
        }
    }

    @Test("Renders populated list without crashing for each filter")
    func populatedAllFilters() {
        let summaries = [
            FoodReactionSummary(foodName: "Avocado", totalCount: 3,
                                happyCount: 2, neutralCount: 1, frownCount: 0),
            FoodReactionSummary(foodName: "Broccoli", totalCount: 2,
                                happyCount: 0, neutralCount: 0, frownCount: 2)
        ]
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: summaries)
            _ = renderHost(view)
        }
    }
}
```

`renderHost` is a small helper that constructs a hosting controller (UIHostingController on iOS, NSHostingController on macOS) for the view-under-test and forces a layout pass. Implementation detail belongs in the implementation plan.

Existing `SummaryViewModelTests` and `FoodReactionAggregatorTests` cover the data layer and require no changes — the picker style swap is a purely visual modification.

## Trade-offs

- **Wheel picker height (~120pt) on iPhone is taller than the segmented control it replaces.** Acceptable because the saving from removing the redundant `Food Ranking` heading roughly offsets the wheel's footprint, and the wheel makes all three filter values discoverable without an extra tap.
- **`AnyView` in `summaryDateButtonStyle` and `filterPicker`.** Type erasure has a small cost but the alternative (separate concrete return types per platform branch) is more code for the same paint result. Both are off the hot path.
- **`UIDevice.current.userInterfaceIdiom` is read at render time, not on size-class changes.** A user dragging the iPad app to a Slide Over compact width keeps the dropdown style. This is acceptable — the wheel on a 320pt-wide compact iPad would feel cramped — but worth noting.
- **`labelsHidden()` removes the picker label from accessibility too.** The accessibility identifier is preserved (`food-ranking-filter`), and the segment text is the accessibility value. VoiceOver still announces the active filter.

## Acceptance criteria

- iPhone: no `Activity Feed` / `Growth` / `Food Ranking` heading text below the segmented control. Activity Feed shows the date-nav row right-aligned. Food Ranking shows a wheel picker for filter, three values visible.
- iPad: same as iPhone except the Food Ranking filter is a dropdown menu.
- macOS: no `Section:` or `Filter:` labels visible. Section picker centered horizontally, max 420pt wide. Date-nav chevrons render with `.plain` button chrome at 28×28pt.
- All existing unit tests pass. New `SummaryViewLayoutTests` passes on iOS simulator and macOS.
- iOS and macOS Xcode builds succeed with no new warnings.

## Out of scope (future work)

- Reverting to a horizontal size-class trigger for the iPad/iPhone picker style split.
- Liquid Glass adoption on the Summary tab toolbar.
- Customizing the wheel picker's tint to match the GG palette.
