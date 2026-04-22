# Vaccination Tracking Feature — Design Spec

**Date:** 2026-04-21
**Status:** Approved
**App:** GentleGuardian (Ditto SDK Demo)

---

## Overview

Add vaccination tracking to GentleGuardian so parents can record their child's immunizations against the recommended schedule for their region. The feature supports the USA (AAP 2026 schedule) and all 30 EU/EEA countries with their country-specific national immunization programs. Vaccination data syncs between caregivers via Ditto P2P, matching the app's existing offline-first architecture.

## Goals

- Let parents track which vaccinations their child has received and when
- Show progress against the recommended schedule for their country
- Highlight overdue vaccinations
- Calculate and display the child's age at each vaccination
- Allow backdating entries (e.g., for parents who start using the app later) with a floor of the child's birth date
- Support ad-hoc "other" vaccinations not in the standard schedule (e.g., COVID, travel vaccines)
- Work with both light and dark mode using the existing GG design system
- Sync vaccination records between family devices via Ditto

## Non-Goals

- Push notifications or reminders for upcoming vaccinations
- Medical advice or clinical decision support
- PDF/export of vaccination records
- Integration with electronic health record systems

---

## Architecture

### Approach: Hybrid Swift Protocol + JSON Data

Vaccine types and the `VaccinationSchedule` protocol are defined in Swift for type safety. Country-specific schedule data (which vaccines, what ages, how many doses) is loaded from a single bundled JSON file keyed by country code.

- **Swift owns the structure**: `VaccineType` enum, `ScheduledDose` struct, `VaccinationSchedule` protocol
- **JSON owns the data**: `vaccination-schedules.json` contains all 31 schedules (USA + 30 EU/EEA)
- Adding a new country means adding a JSON entry — no Swift changes needed

### Data Flow

```
User taps "Log" → LogVaccinationSheet → VaccinationViewModel
  → VaccinationRepository.insert() → DittoManager.execute(DQL INSERT)
  → Ditto live observer fires → Repository updates @Observable array
  → VaccinationView re-renders automatically
```

This matches the existing pattern used by FeedingRepository, DiaperRepository, etc.

---

## Data Model

### Child Model Changes

Three new fields added to the existing `Child` struct:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `vaccinationRegion` | `String?` | `nil` | `"usa"` or `"europe"` |
| `vaccinationCountry` | `String?` | `nil` | ISO 3166-1 alpha-2 code (e.g., `"US"`, `"DE"`, `"FR"`) |
| `isVaccinationTrackingEnabled` | `Bool` | `false` | Controls visibility of the Vaccination tab |

These fields are added to `toDittoDocument()` and `init(from:)` for Ditto serialization. Existing child documents without these fields default to `nil`/`false` — backward compatible.

### VaccineType Enum

Universal set of vaccine identifiers across all supported schedules:

```
hepB, rotavirus, dtap, hib, pcv, ipv, mmr, varicella, hepA,
influenza, tdap, hpv, menACWY, menB, menC, rsv, covid19,
bcg, dengue, mpox, other
```

Each case has a `displayName` (e.g., "Hepatitis B") and `abbreviation` (e.g., "HepB").

### VaccinationRegion Enum

```swift
enum VaccinationRegion: String, Codable, CaseIterable {
    case usa
    case europe
}
```

### ScheduledDose Struct

Represents one dose in a country's recommended schedule:

| Field | Type | Description |
|-------|------|-------------|
| `vaccineType` | `String` | Matches VaccineType raw value |
| `doseNumber` | `Int` | 1-based dose number |
| `recommendedAgeMinMonths` | `Double` | Earliest recommended age in months (0 = birth) |
| `recommendedAgeMaxMonths` | `Double` | Latest recommended age in months (defines the overdue threshold) |
| `ageGroupLabel` | `String` | Display label (e.g., "2 Months", "Birth") |
| `displayName` | `String` | Full name (e.g., "Diphtheria, Tetanus, Pertussis") |
| `abbreviation` | `String` | Short name (e.g., "DTaP") |

### Dose Status Definitions

A dose's status is computed from the child's current age and whether a record exists:

| Status | Condition | Icon | Color |
|--------|-----------|------|-------|
| **Completed** | A `VaccinationRecord` exists for this (vaccineType, doseNumber) | Green checkmark | #2dd4a8 |
| **Overdue** | No record exists AND child's current age > `recommendedAgeMaxMonths` | Red exclamation | #ff6b6b |
| **Pending** | No record exists AND child's current age is within `[recommendedAgeMinMonths, recommendedAgeMaxMonths]` | Amber ellipsis | #f0a830 |
| **Upcoming** | No record exists AND child's current age < `recommendedAgeMinMonths` | Gray circle | dimmed |

An age group's overall status is the worst status among its doses: overdue > pending > upcoming > completed.

### VaccinationRecord Model (New Ditto Collection)

Stored in collection `vaccination_records`, synced via P2P:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | UUID, maps to `_id` in Ditto |
| `childId` | `String` | Foreign key to child |
| `vaccineType` | `String` | Matches VaccineType raw value (or `"other"`) |
| `doseNumber` | `Int` | 1-based dose number (0 for "other" type) |
| `dateAdministered` | `Date` | When the vaccine was given |
| `notes` | `String?` | Optional free-text notes |
| `customVaccineName` | `String?` | Only for `vaccineType == "other"` |
| `customVaccineDescription` | `String?` | Only for `vaccineType == "other"` |
| `createdAt` | `Date` | Record creation timestamp |
| `updatedAt` | `Date` | Last modification timestamp |
| `isArchived` | `Bool` | Soft delete flag |
| `createdByDeviceId` | `String` | Device that created the record |

### vaccination-schedules.json Structure

```json
{
  "US": {
    "name": "United States (AAP 2026)",
    "source": "American Academy of Pediatrics",
    "doses": [
      {
        "vaccineType": "hepB",
        "doseNumber": 1,
        "recommendedAgeMinMonths": 0,
      "recommendedAgeMaxMonths": 0,
        "ageGroupLabel": "Birth",
        "displayName": "Hepatitis B",
        "abbreviation": "HepB"
      },
      ...
    ]
  },
  "DE": {
    "name": "Germany (STIKO 2026)",
    "source": "Robert Koch Institute",
    "doses": [ ... ]
  },
  ...
}
```

---

## Supported Countries

### USA
Source: AAP 2026 Recommended Childhood and Adolescent Immunization Schedule

Vaccines (birth through 18 years):
- **Birth**: HepB (dose 1), RSV-mAb/Nirsevimab
- **2 months**: DTaP (1), IPV (1), Hib (1), PCV15/20 (1), RV (1), HepB (2)
- **4 months**: DTaP (2), IPV (2), Hib (2), PCV (2), RV (2)
- **6 months**: DTaP (3), IPV (3), PCV (3), RV (3 if RV5), HepB (3), Influenza (annual)
- **12-15 months**: MMR (1), Varicella (1), HepA (1), Hib (booster), PCV (booster)
- **15-18 months**: DTaP (4)
- **4-6 years**: DTaP (5), IPV (4), MMR (2), Varicella (2)
- **11-12 years**: Tdap, HPV, MenACWY (1)
- **16 years**: MenACWY (2)
- **16-18 years**: MenB (clinical decision)

### EU/EEA Countries (30 total)

All schedules sourced from the ECDC Vaccine Scheduler and national health authorities:

| Code | Country | Code | Country |
|------|---------|------|---------|
| AT | Austria | LT | Lithuania |
| BE | Belgium | LU | Luxembourg |
| BG | Bulgaria | LV | Latvia |
| HR | Croatia | MT | Malta |
| CY | Cyprus | NL | Netherlands |
| CZ | Czechia | NO | Norway |
| DK | Denmark | PL | Poland |
| EE | Estonia | PT | Portugal |
| FI | Finland | RO | Romania |
| FR | France | SK | Slovakia |
| DE | Germany | SI | Slovenia |
| GR | Greece | ES | Spain |
| HU | Hungary | SE | Sweden |
| IS | Iceland | IE | Ireland |
| IT | Italy | LI | Liechtenstein |

**Core vaccines common to all EU/EEA countries:**
Measles, Mumps, Rubella, Diphtheria, Tetanus, Pertussis, Polio, Hib, HPV

**Additional vaccines that vary by country:**
HepA, HepB, Influenza, Meningococcal (MenACWY, MenB, MenC), Pneumococcal, Rotavirus, BCG (Tuberculosis), Varicella

Each country's specific schedule (vaccines, doses, and timing) will be encoded in the JSON data file based on the ECDC Vaccine Scheduler and each country's national immunization authority.

---

## UI Design

### Registration Flow

New section added to `RegisterChildView` after the prematurity section:

1. **Region picker** — Segmented control: "USA" / "Europe"
2. **Country picker** (Europe only) — Scrollable picker showing country name + flag emoji
3. **Tracking toggle** — "Track vaccinations?" switch, default off
4. **Explainer text** — "When enabled, a Vaccinations tab helps you track your child's immunization schedule based on [source name] recommendations."

### Child Profile

New **Vaccination Settings** card in `ChildProfileView` allowing post-registration changes:
- Change region/country
- Toggle tracking on/off
- Changes take effect immediately (tab appears/disappears)

### Conditional 5th Tab

`ContentView` conditionally renders the Vaccination tab:

```swift
if activeChild.isVaccinationTrackingEnabled {
    Tab("Vaccines", systemImage: "syringe", value: .vaccination) { ... }
}
```

`AppTab` enum gains a `.vaccination` case. iPad/Mac sidebar also conditionally shows "Vaccines". The app stays at 4 tabs when vaccination tracking is disabled.

### Vaccination Tab — Main View

**Layout: Collapsed Age Groups** (chosen design)

1. **Header**: "Vaccinations" title with child name and schedule source (e.g., "USA (AAP)")

2. **Progress summary card** (gradient style matching existing app):
   - Dose count: "12 / 28 doses completed"
   - Circular progress indicator with percentage
   - Three stat pills: "Next Due", "Overdue" count, "Up to date" count

3. **Age-grouped checklist**: Each age milestone is a collapsed row showing:
   - Status icon: green checkmark (all complete), amber ellipsis (partial), red exclamation (overdue), gray circle (upcoming/future)
   - Age label: "Birth", "2 Months", "4 Months", etc.
   - Completion count: "4 of 6 doses"
   - Overdue groups get a red left border accent
   - Future groups (child hasn't reached this age yet) are dimmed
   - Tapping expands into the age group detail view (navigation push)

4. **"Log Other Vaccine" button**: Persistent button at the bottom of the age group list for ad-hoc vaccinations

5. **Other Vaccines section**: Appears below the schedule list when custom vaccine records exist. Shows each custom entry with name, description, date, and age at administration.

### Age Group Detail View

**Layout: Individual + Batch Logging** (chosen design)

Navigation push from tapping an age group row. Shows:

1. **Back navigation** to main vaccination view

2. **Age context card**: "Recommended at 2 months old — Sandra was 2m on May 15, 2026"

3. **Vaccine list** for this age group:
   - **Completed vaccines**: Green checkmark, vaccine name + dose number, full name, date administered + age at vaccination (e.g., "May 18, 2026 · at 2m 3d old"). Tappable to view/edit details.
   - **Pending/overdue vaccines**: Red exclamation icon, red left border accent, "Not recorded · overdue" label, individual "Log" button on each row

4. **"Log All Remaining (N)" button**: At bottom, for batch-logging multiple vaccines from a single doctor visit. Opens a sheet with checkboxes for all remaining vaccines, single date picker, and optional notes.

### Log Vaccination Sheet (Individual)

Presented as a SwiftUI sheet when tapping an individual "Log" button:

- **Vaccine info** (read-only): name, dose number, description
- **Date picker**: Range constrained to `child.birthday...Date()` (cannot be before birth, cannot be in the future)
- **Age display** (computed): Shows child's age at the selected date, updates live as date changes
- **Notes** (optional): Multi-line text field
- **Save button**

### Log Batch Vaccination Sheet

Presented when tapping "Log All Remaining":

- **Checkboxes**: List of all remaining (unlogged) vaccines for this age group, all checked by default. User can uncheck vaccines not given.
- **Date picker**: Same constraints as individual log
- **Age display**: Same live computation
- **Notes** (optional): Shared across all selected vaccines
- **Save button**: Creates one `VaccinationRecord` per checked vaccine, all with the same date and notes

### Edit/Delete Vaccination Record

Tapping a completed vaccine in the age group detail view opens a detail sheet showing:

- **Vaccine info** (read-only): name, dose number, description
- **Date administered**: Editable date picker (same constraints)
- **Age at vaccination**: Updates live
- **Notes**: Editable
- **Save Changes** button
- **Delete** button (text, destructive style): Soft-deletes the record (`isArchived = true`), which restores the dose to "pending/overdue" status. Requires confirmation alert.

For "other" type vaccines, the custom name and description are also editable.

### Log Other Vaccine Sheet

Presented when tapping "Log Other Vaccine":

- **Vaccine name** (required): Free-text field
- **Description** (optional): Free-text field (e.g., "Required for travel to Brazil")
- **Date picker**: Same constraints as standard logging
- **Age display**: Same live computation
- **Notes** (optional): Multi-line text field
- **Save button**: Creates a `VaccinationRecord` with `vaccineType: "other"` and the custom fields populated

### Light and Dark Mode

All views use the existing `GGAdaptiveColors` system with `isNightMode` environment value. The vaccination tab follows the same patterns as Home, Summary, etc.:
- Dark mode: dark backgrounds (#0f1923, #1a2a3a), light text, teal accents
- Light mode: light backgrounds, dark text, same teal accent colors
- Progress card uses the existing gradient style (matching the "Last Feeding" and "Total Events" cards)
- Status colors: green (#2dd4a8) for complete, amber for partial, red for overdue, dimmed for future

---

## Validation Rules

| Rule | Enforcement |
|------|-------------|
| Date ≥ child's birthday | DatePicker range floor |
| Date ≤ today | DatePicker range ceiling |
| No duplicate dose | UI hides "Log" button for completed doses; repository rejects duplicates on (childId, vaccineType, doseNumber) |
| Overdue calculation | Dose is overdue if child's current age > recommended age and dose not logged |
| Age at vaccination | Computed as `dateAdministered - child.birthday`, displayed as "Xm Yd old" |
| Custom vaccine name required | Save button disabled until name is non-empty (for "other" type) |

---

## New Files

| Layer | File | Purpose |
|-------|------|---------|
| Models | `Core/Models/VaccinationRecord.swift` | Ditto-synced vaccination record |
| Models | `Core/Models/Enums/VaccineType.swift` | Universal vaccine type enum |
| Models | `Core/Models/Enums/VaccinationRegion.swift` | USA / Europe region enum |
| Models | `Core/Models/VaccinationSchedule.swift` | Protocol + ScheduledDose struct + schedule loading |
| Repository | `Core/Repositories/VaccinationRepository.swift` | DQL observers, CRUD for vaccination_records |
| Service | `Core/Services/VaccinationScheduleService.swift` | Loads JSON, resolves schedule by country, computes progress |
| Resources | `GentleGuardian/Resources/vaccination-schedules.json` | All 31 country schedules |
| Views | `Features/Vaccination/Views/VaccinationView.swift` | Main tab: progress + age group list |
| Views | `Features/Vaccination/Views/AgeGroupDetailView.swift` | Expanded vaccine list for one age group |
| Views | `Features/Vaccination/Views/LogVaccinationSheet.swift` | Individual vaccine logging sheet |
| Views | `Features/Vaccination/Views/LogBatchVaccinationSheet.swift` | Batch logging sheet |
| Views | `Features/Vaccination/Views/LogOtherVaccineSheet.swift` | Custom/other vaccine logging sheet |
| ViewModels | `Features/Vaccination/ViewModels/VaccinationViewModel.swift` | Progress computation, age group aggregation |
| ViewModels | `Features/Vaccination/ViewModels/AgeGroupDetailViewModel.swift` | Detail view logic, overdue detection |
| ViewModels | `Features/Vaccination/ViewModels/LogVaccinationViewModel.swift` | Log form validation, age computation, save |

## Modified Files

| File | Change |
|------|--------|
| `Core/Models/Child.swift` | Add vaccinationRegion, vaccinationCountry, isVaccinationTrackingEnabled fields |
| `App/ContentView.swift` | Add conditional 5th tab, update AppTab enum, wire VaccinationRepository |
| `App/AppConstants.swift` | Add `vaccination_records` collection name to `Collections` |
| `App/GentleGuardianApp.swift` | Initialize VaccinationRepository, pass to ContentView |
| `Features/Onboarding/Views/RegisterChildView.swift` | Add vaccination settings section |
| `Features/Onboarding/ViewModels/RegisterChildViewModel.swift` | Add vaccination fields and validation |
| `Features/ChildProfile/Views/ChildProfileView.swift` | Add vaccination settings card |
| `Features/ChildProfile/ViewModels/ChildProfileViewModel.swift` | Add vaccination field editing |
| `Core/Ditto/DittoManager.swift` | Subscribe to vaccination_records collection |
| `project.yml` | Add new source files to Xcode project spec |

---

## Ditto Sync

- `vaccination_records` collection added to `AppConstants.Collections.all` array
- `SmallPeersOnly` sync scope applied (matching all other collections)
- Subscription created in `DittoManager` for `vaccination_records WHERE childId = :childId AND isArchived = false`
- Child document fields (region, country, tracking toggle) sync as part of the existing `children` collection

---

## Testing Strategy

- **Unit tests**: VaccinationScheduleService (JSON loading, schedule resolution, progress computation, overdue detection, age calculation)
- **Unit tests**: VaccinationRecord model (serialization, validation)
- **Unit tests**: ViewModels (form validation, date constraints, duplicate prevention)
- **Mock tests**: VaccinationRepository using MockDittoManager (matching existing test patterns)
- **UI verification**: Manual testing in light mode, dark mode, and night mode across all new views
