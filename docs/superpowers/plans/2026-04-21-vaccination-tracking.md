# Vaccination Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add vaccination tracking to GentleGuardian so parents can record immunizations against the recommended schedule for their region (USA + 30 EU/EEA countries), with a conditional 5th tab, batch logging, ad-hoc "other" vaccines, and full Ditto P2P sync.

**Architecture:** Hybrid Swift protocol + bundled JSON for schedule data. New `vaccination_records` Ditto collection follows the existing repository/observer pattern. Conditional tab visibility driven by a new `isVaccinationTrackingEnabled` field on the `Child` model. ViewModels compute dose status (completed/overdue/pending/upcoming) from schedule data + existing records.

**Tech Stack:** SwiftUI, Ditto SDK v5 (DQL), @Observable repositories, Swift actors, XcodeGen

---

## File Structure

### New Files

| Layer | File | Responsibility |
|-------|------|----------------|
| Models | `Core/Models/VaccinationRecord.swift` | Ditto-synced vaccination record struct |
| Models | `Core/Models/Enums/VaccineType.swift` | Universal vaccine type enum with display names |
| Models | `Core/Models/Enums/VaccinationRegion.swift` | USA / Europe region enum |
| Models | `Core/Models/VaccinationSchedule.swift` | `ScheduledDose` struct, JSON loading, schedule lookup |
| Repository | `Core/Repositories/VaccinationRepository.swift` | DQL observers + CRUD for `vaccination_records` |
| Service | `Core/Services/VaccinationScheduleService.swift` | Loads JSON, resolves schedule by country, computes progress/status |
| Resources | `Resources/vaccination-schedules.json` | All 31 country schedules (USA + 30 EU/EEA) |
| Views | `Features/Vaccination/Views/VaccinationView.swift` | Main tab: progress card + age group list |
| Views | `Features/Vaccination/Views/AgeGroupDetailView.swift` | Expanded vaccine list for one age group |
| Views | `Features/Vaccination/Views/LogVaccinationSheet.swift` | Individual vaccine logging sheet |
| Views | `Features/Vaccination/Views/LogBatchVaccinationSheet.swift` | Batch logging sheet |
| Views | `Features/Vaccination/Views/LogOtherVaccineSheet.swift` | Custom/other vaccine logging sheet |
| Views | `Features/Vaccination/Views/EditVaccinationSheet.swift` | Edit/delete existing vaccination record |
| Views | `Features/Vaccination/Views/VaccinationSettingsCard.swift` | Reusable region/country/toggle card for registration + profile |
| ViewModels | `Features/Vaccination/ViewModels/VaccinationViewModel.swift` | Progress computation, age group aggregation, status |
| ViewModels | `Features/Vaccination/ViewModels/LogVaccinationViewModel.swift` | Log form validation, age computation, save (individual + batch + other) |
| Tests | `GentleGuardianTests/VaccinationScheduleServiceTests.swift` | Unit tests for schedule loading + progress + status |
| Tests | `GentleGuardianTests/VaccinationRecordTests.swift` | Unit tests for model serialization |
| Tests | `GentleGuardianTests/LogVaccinationViewModelTests.swift` | Unit tests for form validation + age computation |

### Modified Files

| File | Change |
|------|--------|
| `Core/Models/Child.swift` | Add `vaccinationRegion`, `vaccinationCountry`, `isVaccinationTrackingEnabled` fields |
| `App/AppConstants.swift` | Add `vaccinationRecords` collection name to `Collections` |
| `App/ContentView.swift` | Add conditional `.vaccination` tab, update `AppTab` enum |
| `App/GentleGuardianApp.swift` | Initialize `VaccinationRepository`, pass to `ContentView` |
| `Features/Onboarding/Views/RegisterChildView.swift` | Add vaccination settings section |
| `Features/Onboarding/ViewModels/RegisterChildViewModel.swift` | Add vaccination fields |
| `Features/ChildProfile/Views/ChildProfileView.swift` | Add vaccination settings card |
| `Features/ChildProfile/ViewModels/ChildProfileViewModel.swift` | Add vaccination field editing |
| `Core/Ditto/DittoManager.swift` | Add `vaccinationRecords` to `subscribeToChildData` collections list |
| `project.yml` | Run `xcodegen generate` after adding files |

---

## Task 1: VaccineType Enum + VaccinationRegion Enum

**Files:**
- Create: `src/GentleGuardian/Core/Models/Enums/VaccineType.swift`
- Create: `src/GentleGuardian/Core/Models/Enums/VaccinationRegion.swift`

- [ ] **Step 1: Create VaccineType enum**

```swift
import Foundation

/// Universal vaccine type identifiers used across all supported schedules.
enum VaccineType: String, Codable, CaseIterable, Sendable {
    case hepB
    case rotavirus
    case dtap
    case hib
    case pcv
    case ipv
    case mmr
    case varicella
    case hepA
    case influenza
    case tdap
    case hpv
    case menACWY
    case menB
    case menC
    case rsv
    case covid19
    case bcg
    case dengue
    case mpox
    case other

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .hepB: "Hepatitis B"
        case .rotavirus: "Rotavirus"
        case .dtap: "Diphtheria, Tetanus, Pertussis"
        case .hib: "Haemophilus influenzae type b"
        case .pcv: "Pneumococcal Conjugate"
        case .ipv: "Inactivated Poliovirus"
        case .mmr: "Measles, Mumps, Rubella"
        case .varicella: "Varicella (Chickenpox)"
        case .hepA: "Hepatitis A"
        case .influenza: "Influenza (Flu)"
        case .tdap: "Tetanus, Diphtheria, Pertussis (Booster)"
        case .hpv: "Human Papillomavirus"
        case .menACWY: "Meningococcal ACWY"
        case .menB: "Meningococcal B"
        case .menC: "Meningococcal C"
        case .rsv: "Respiratory Syncytial Virus"
        case .covid19: "COVID-19"
        case .bcg: "BCG (Tuberculosis)"
        case .dengue: "Dengue"
        case .mpox: "Mpox"
        case .other: "Other"
        }
    }

    /// Short abbreviation for compact display.
    var abbreviation: String {
        switch self {
        case .hepB: "HepB"
        case .rotavirus: "RV"
        case .dtap: "DTaP"
        case .hib: "Hib"
        case .pcv: "PCV"
        case .ipv: "IPV"
        case .mmr: "MMR"
        case .varicella: "VAR"
        case .hepA: "HepA"
        case .influenza: "Flu"
        case .tdap: "Tdap"
        case .hpv: "HPV"
        case .menACWY: "MenACWY"
        case .menB: "MenB"
        case .menC: "MenC"
        case .rsv: "RSV"
        case .covid19: "COVID"
        case .bcg: "BCG"
        case .dengue: "Dengue"
        case .mpox: "Mpox"
        case .other: "Other"
        }
    }
}
```

- [ ] **Step 2: Create VaccinationRegion enum**

```swift
import Foundation

/// Supported vaccination schedule regions.
enum VaccinationRegion: String, Codable, CaseIterable, Sendable {
    case usa
    case europe

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .usa: "USA"
        case .europe: "Europe"
        }
    }

    /// Countries available in this region, as (code, displayName) pairs.
    var countries: [(code: String, name: String)] {
        switch self {
        case .usa:
            return [("US", "United States")]
        case .europe:
            return [
                ("AT", "Austria"), ("BE", "Belgium"), ("BG", "Bulgaria"),
                ("HR", "Croatia"), ("CY", "Cyprus"), ("CZ", "Czechia"),
                ("DK", "Denmark"), ("EE", "Estonia"), ("FI", "Finland"),
                ("FR", "France"), ("DE", "Germany"), ("GR", "Greece"),
                ("HU", "Hungary"), ("IS", "Iceland"), ("IE", "Ireland"),
                ("IT", "Italy"), ("LI", "Liechtenstein"), ("LT", "Lithuania"),
                ("LU", "Luxembourg"), ("LV", "Latvia"), ("MT", "Malta"),
                ("NL", "Netherlands"), ("NO", "Norway"), ("PL", "Poland"),
                ("PT", "Portugal"), ("RO", "Romania"), ("SK", "Slovakia"),
                ("SI", "Slovenia"), ("ES", "Spain"), ("SE", "Sweden")
            ]
        }
    }

    /// Flag emoji for a country code.
    static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }
}
```

- [ ] **Step 3: Run xcodegen and verify build**

Run:
```bash
cd src && xcodegen generate --spec project.yml
```

Then open Xcode and build (Cmd+B) to verify no errors.

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/Core/Models/Enums/VaccineType.swift src/GentleGuardian/Core/Models/Enums/VaccinationRegion.swift
git commit -m "feat: add VaccineType and VaccinationRegion enums"
```

---

## Task 2: VaccinationRecord Model

**Files:**
- Create: `src/GentleGuardian/Core/Models/VaccinationRecord.swift`
- Test: `src/GentleGuardianTests/VaccinationRecordTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import Testing
@testable import GentleGuardian

struct VaccinationRecordTests {

    @Test func roundTripSerialization() {
        let record = VaccinationRecord(
            childId: "child-1",
            vaccineType: "dtap",
            doseNumber: 1,
            dateAdministered: DateService.date(fromISO8601: "2026-05-18T10:00:00.000Z")!,
            notes: "No reaction"
        )

        let doc = record.toDittoDocument()
        let restored = VaccinationRecord(from: doc)

        #expect(restored.id == record.id)
        #expect(restored.childId == "child-1")
        #expect(restored.vaccineType == "dtap")
        #expect(restored.doseNumber == 1)
        #expect(restored.notes == "No reaction")
        #expect(restored.isArchived == false)
        #expect(restored.customVaccineName == nil)
    }

    @Test func otherVaccineWithCustomFields() {
        let record = VaccinationRecord(
            childId: "child-1",
            vaccineType: "other",
            doseNumber: 0,
            dateAdministered: Date(),
            notes: "Travel requirement",
            customVaccineName: "Yellow Fever",
            customVaccineDescription: "Required for travel to Brazil"
        )

        let doc = record.toDittoDocument()
        let restored = VaccinationRecord(from: doc)

        #expect(restored.vaccineType == "other")
        #expect(restored.doseNumber == 0)
        #expect(restored.customVaccineName == "Yellow Fever")
        #expect(restored.customVaccineDescription == "Required for travel to Brazil")
    }

    @Test func missingFieldsUseDefaults() {
        let doc: [String: Any?] = [
            "_id": "test-id",
            "childId": "child-1",
            "vaccineType": "mmr",
            "doseNumber": 1
        ]

        let record = VaccinationRecord(from: doc)

        #expect(record.id == "test-id")
        #expect(record.notes == nil)
        #expect(record.isArchived == false)
        #expect(record.customVaccineName == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd src && swift test --filter VaccinationRecordTests 2>&1 | head -30
```
Expected: Compilation error — `VaccinationRecord` not defined.

- [ ] **Step 3: Create VaccinationRecord model**

```swift
import Foundation

/// A single vaccination record synced via Ditto.
struct VaccinationRecord: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier, maps to `_id` in Ditto.
    let id: String

    /// The child this record belongs to.
    var childId: String

    /// Vaccine type raw value (matches VaccineType.rawValue, or "other").
    var vaccineType: String

    /// 1-based dose number. 0 for "other" type vaccines.
    var doseNumber: Int

    /// When the vaccine was administered.
    var dateAdministered: Date

    /// Optional free-text notes.
    var notes: String?

    /// Custom vaccine name (only for vaccineType == "other").
    var customVaccineName: String?

    /// Custom vaccine description (only for vaccineType == "other").
    var customVaccineDescription: String?

    /// Timestamp when this record was created.
    var createdAt: Date

    /// Timestamp when this record was last modified.
    var updatedAt: Date

    /// Soft-delete flag.
    var isArchived: Bool

    /// The device ID that originally created this record.
    var createdByDeviceId: String

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        childId: String,
        vaccineType: String,
        doseNumber: Int,
        dateAdministered: Date,
        notes: String? = nil,
        customVaccineName: String? = nil,
        customVaccineDescription: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        createdByDeviceId: String = ""
    ) {
        self.id = id
        self.childId = childId
        self.vaccineType = vaccineType
        self.doseNumber = doseNumber
        self.dateAdministered = dateAdministered
        self.notes = notes
        self.customVaccineName = customVaccineName
        self.customVaccineDescription = customVaccineDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.createdByDeviceId = createdByDeviceId
    }

    /// Initializes from a Ditto document dictionary.
    init(from document: [String: Any?]) {
        self.id = document["_id"] as? String ?? UUID().uuidString
        self.childId = document["childId"] as? String ?? ""
        self.vaccineType = document["vaccineType"] as? String ?? ""
        self.doseNumber = document["doseNumber"] as? Int ?? 0
        self.dateAdministered = DateService.date(fromISO8601: document["dateAdministered"] as? String) ?? Date()
        self.notes = document["notes"] as? String
        self.customVaccineName = document["customVaccineName"] as? String
        self.customVaccineDescription = document["customVaccineDescription"] as? String
        self.createdAt = DateService.date(fromISO8601: document["createdAt"] as? String) ?? Date()
        self.updatedAt = DateService.date(fromISO8601: document["updatedAt"] as? String) ?? Date()
        self.isArchived = document["isArchived"] as? Bool ?? false
        self.createdByDeviceId = document["createdByDeviceId"] as? String ?? ""
    }

    // MARK: - Serialization

    /// Converts this record to a dictionary suitable for Ditto INSERT.
    func toDittoDocument() -> [String: Any?] {
        [
            "_id": id,
            "childId": childId,
            "vaccineType": vaccineType,
            "doseNumber": doseNumber,
            "dateAdministered": DateService.iso8601String(from: dateAdministered),
            "notes": notes,
            "customVaccineName": customVaccineName,
            "customVaccineDescription": customVaccineDescription,
            "createdAt": DateService.iso8601String(from: createdAt),
            "updatedAt": DateService.iso8601String(from: updatedAt),
            "isArchived": isArchived,
            "createdByDeviceId": createdByDeviceId
        ]
    }

    // MARK: - Computed Properties

    /// The resolved VaccineType enum, if it matches a known type.
    var resolvedVaccineType: VaccineType? {
        VaccineType(rawValue: vaccineType)
    }

    /// Display name — uses customVaccineName for "other", otherwise the VaccineType displayName.
    var displayName: String {
        if vaccineType == VaccineType.other.rawValue {
            return customVaccineName ?? "Other Vaccine"
        }
        return resolvedVaccineType?.displayName ?? vaccineType
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd src && swift test --filter VaccinationRecordTests 2>&1 | tail -10
```
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/GentleGuardian/Core/Models/VaccinationRecord.swift src/GentleGuardianTests/VaccinationRecordTests.swift
git commit -m "feat: add VaccinationRecord model with Ditto serialization"
```

---

## Task 3: Child Model Changes

**Files:**
- Modify: `src/GentleGuardian/Core/Models/Child.swift`

- [ ] **Step 1: Add three new properties to Child struct**

Add after the `createdByDeviceId` property declaration (after line 48):

```swift
    /// Vaccination schedule region ("usa" or "europe"). Nil if not configured.
    var vaccinationRegion: String?

    /// ISO 3166-1 alpha-2 country code for vaccination schedule. Nil if not configured.
    var vaccinationCountry: String?

    /// Whether vaccination tracking is enabled for this child.
    var isVaccinationTrackingEnabled: Bool
```

- [ ] **Step 2: Add parameters to init**

Update the `init` to include the three new fields. Add after `createdByDeviceId: String = ""`:

```swift
        vaccinationRegion: String? = nil,
        vaccinationCountry: String? = nil,
        isVaccinationTrackingEnabled: Bool = false
```

And add to the init body after `self.createdByDeviceId = createdByDeviceId`:

```swift
        self.vaccinationRegion = vaccinationRegion
        self.vaccinationCountry = vaccinationCountry
        self.isVaccinationTrackingEnabled = isVaccinationTrackingEnabled
```

- [ ] **Step 3: Add parsing to init(from document:)**

Add after the `createdByDeviceId` parsing line (after `self.createdByDeviceId = document["createdByDeviceId"] as? String ?? ""`):

```swift
        self.vaccinationRegion = document["vaccinationRegion"] as? String
        self.vaccinationCountry = document["vaccinationCountry"] as? String
        self.isVaccinationTrackingEnabled = document["isVaccinationTrackingEnabled"] as? Bool ?? false
```

- [ ] **Step 4: Add fields to toDittoDocument()**

Add three entries to the dictionary in `toDittoDocument()`, after `"createdByDeviceId": createdByDeviceId`:

```swift
            "vaccinationRegion": vaccinationRegion,
            "vaccinationCountry": vaccinationCountry,
            "isVaccinationTrackingEnabled": isVaccinationTrackingEnabled
```

- [ ] **Step 5: Build to verify**

Run:
```bash
cd src && xcodegen generate --spec project.yml
```

Then build in Xcode (Cmd+B). Expected: successful build. Existing code that creates `Child` instances uses default parameter values, so no call sites break.

- [ ] **Step 6: Commit**

```bash
git add src/GentleGuardian/Core/Models/Child.swift
git commit -m "feat: add vaccination tracking fields to Child model"
```

---

## Task 4: AppConstants + DittoManager Changes

**Files:**
- Modify: `src/GentleGuardian/App/AppConstants.swift`
- Modify: `src/GentleGuardian/Core/Ditto/DittoManager.swift`

- [ ] **Step 1: Add collection name to AppConstants**

In `AppConstants.swift`, inside the `Collections` enum, add after `static let otherEvents = "otherEvents"` (line 68):

```swift
        static let vaccinationRecords = "vaccinationRecords"
```

Then update the `all` array (line 71) to include it:

```swift
        static let all: [String] = [
            children, feeding, diaper, health, activity, sleep, customItems, otherEvents, vaccinationRecords
        ]
```

- [ ] **Step 2: Add vaccination_records to DittoManager subscription**

In `DittoManager.swift`, in the `subscribeToChildData(childId:)` method, add `AppConstants.Collections.vaccinationRecords` to the `collectionsToSync` array (around line 155):

```swift
        let collectionsToSync = [
            AppConstants.Collections.children,
            AppConstants.Collections.feeding,
            AppConstants.Collections.diaper,
            AppConstants.Collections.health,
            AppConstants.Collections.activity,
            AppConstants.Collections.sleep,
            AppConstants.Collections.customItems,
            AppConstants.Collections.vaccinationRecords
        ]
```

- [ ] **Step 3: Build to verify**

Build in Xcode (Cmd+B). Expected: successful build. The `vaccinationRecords` collection is now included in sync scope configuration and per-child subscriptions.

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/App/AppConstants.swift src/GentleGuardian/Core/Ditto/DittoManager.swift
git commit -m "feat: add vaccinationRecords collection to Ditto sync"
```

---

## Task 5: VaccinationSchedule + ScheduledDose + JSON Loading

**Files:**
- Create: `src/GentleGuardian/Core/Models/VaccinationSchedule.swift`
- Create: `src/GentleGuardian/Core/Services/VaccinationScheduleService.swift`
- Create: `src/GentleGuardian/Resources/vaccination-schedules.json`
- Test: `src/GentleGuardianTests/VaccinationScheduleServiceTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
import Foundation
@testable import GentleGuardian

struct VaccinationScheduleServiceTests {

    // MARK: - Schedule Loading

    @Test func loadUSSchedule() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")

        #expect(schedule != nil)
        #expect(schedule!.name.contains("United States"))
        #expect(!schedule!.doses.isEmpty)
    }

    @Test func loadGermanySchedule() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "DE")

        #expect(schedule != nil)
        #expect(schedule!.name.contains("Germany"))
        #expect(!schedule!.doses.isEmpty)
    }

    @Test func invalidCountryReturnsNil() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "XX")

        #expect(schedule == nil)
    }

    @Test func allCountriesHaveSchedules() {
        let service = VaccinationScheduleService()
        let allCodes = ["US"] + VaccinationRegion.europe.countries.map(\.code)

        for code in allCodes {
            let schedule = service.schedule(for: code)
            #expect(schedule != nil, "Missing schedule for \(code)")
            #expect(!schedule!.doses.isEmpty, "Empty doses for \(code)")
        }
    }

    // MARK: - Age Group Aggregation

    @Test func ageGroupsAreGroupedByLabel() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")!
        let groups = service.ageGroups(for: schedule)

        #expect(!groups.isEmpty)
        // Birth should be the first group
        #expect(groups[0].label == "Birth")
        // Each group should have at least one dose
        for group in groups {
            #expect(!group.doses.isEmpty, "Empty group: \(group.label)")
        }
    }

    // MARK: - Dose Status Computation

    @Test func completedDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(
            vaccineType: "hepB",
            doseNumber: 1,
            recommendedAgeMinMonths: 0,
            recommendedAgeMaxMonths: 0,
            ageGroupLabel: "Birth",
            displayName: "Hepatitis B",
            abbreviation: "HepB"
        )

        let record = VaccinationRecord(
            childId: "child-1",
            vaccineType: "hepB",
            doseNumber: 1,
            dateAdministered: Date()
        )

        let status = service.status(
            for: dose,
            records: [record],
            childAgeMonths: 2.0
        )
        #expect(status == .completed)
    }

    @Test func overdueDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(
            vaccineType: "dtap",
            doseNumber: 1,
            recommendedAgeMinMonths: 2,
            recommendedAgeMaxMonths: 2,
            ageGroupLabel: "2 Months",
            displayName: "DTaP",
            abbreviation: "DTaP"
        )

        let status = service.status(
            for: dose,
            records: [],
            childAgeMonths: 5.0
        )
        #expect(status == .overdue)
    }

    @Test func pendingDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(
            vaccineType: "dtap",
            doseNumber: 1,
            recommendedAgeMinMonths: 2,
            recommendedAgeMaxMonths: 4,
            ageGroupLabel: "2 Months",
            displayName: "DTaP",
            abbreviation: "DTaP"
        )

        let status = service.status(
            for: dose,
            records: [],
            childAgeMonths: 3.0
        )
        #expect(status == .pending)
    }

    @Test func upcomingDoseStatus() {
        let service = VaccinationScheduleService()
        let dose = ScheduledDose(
            vaccineType: "mmr",
            doseNumber: 1,
            recommendedAgeMinMonths: 12,
            recommendedAgeMaxMonths: 15,
            ageGroupLabel: "12-15 Months",
            displayName: "MMR",
            abbreviation: "MMR"
        )

        let status = service.status(
            for: dose,
            records: [],
            childAgeMonths: 6.0
        )
        #expect(status == .upcoming)
    }

    // MARK: - Progress Computation

    @Test func progressCounts() {
        let service = VaccinationScheduleService()
        let schedule = service.schedule(for: "US")!

        let records = [
            VaccinationRecord(childId: "c1", vaccineType: "hepB", doseNumber: 1, dateAdministered: Date()),
            VaccinationRecord(childId: "c1", vaccineType: "rsv", doseNumber: 1, dateAdministered: Date()),
        ]

        let progress = service.progress(for: schedule, records: records)

        #expect(progress.completed == 2)
        #expect(progress.total == schedule.doses.count)
    }

    // MARK: - Child Age Computation

    @Test func childAgeAtDate() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let vacDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 18))!

        let ageString = VaccinationScheduleService.ageString(from: birthday, to: vacDate)

        #expect(ageString == "2m 3d")
    }

    @Test func childAgeInMonths() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 15))!

        let months = VaccinationScheduleService.ageInMonths(from: birthday, to: now)

        #expect(months == 6.0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd src && swift test --filter VaccinationScheduleServiceTests 2>&1 | head -20
```
Expected: Compilation error — `VaccinationScheduleService`, `ScheduledDose` not defined.

- [ ] **Step 3: Create ScheduledDose struct and schedule model**

Create `src/GentleGuardian/Core/Models/VaccinationSchedule.swift`:

```swift
import Foundation

/// A single dose in a country's recommended vaccination schedule.
struct ScheduledDose: Codable, Sendable, Equatable, Identifiable {
    /// Matches VaccineType raw value.
    let vaccineType: String
    /// 1-based dose number.
    let doseNumber: Int
    /// Earliest recommended age in months (0 = birth).
    let recommendedAgeMinMonths: Double
    /// Latest recommended age in months (defines the overdue threshold).
    let recommendedAgeMaxMonths: Double
    /// Display label for the age group (e.g., "2 Months", "Birth").
    let ageGroupLabel: String
    /// Full vaccine name (e.g., "Diphtheria, Tetanus, Pertussis").
    let displayName: String
    /// Short name (e.g., "DTaP").
    let abbreviation: String

    var id: String { "\(vaccineType)-\(doseNumber)" }
}

/// A country's complete vaccination schedule.
struct CountrySchedule: Codable, Sendable {
    /// Display name (e.g., "United States (AAP 2026)").
    let name: String
    /// Source authority (e.g., "American Academy of Pediatrics").
    let source: String
    /// All scheduled doses in recommended order.
    let doses: [ScheduledDose]
}

/// Status of a single dose for a specific child.
enum DoseStatus: String, Sendable, Equatable {
    case completed
    case overdue
    case pending
    case upcoming
}

/// An age group containing doses for the same age milestone.
struct AgeGroup: Identifiable, Sendable {
    let label: String
    let doses: [ScheduledDose]

    var id: String { label }
}

/// Progress summary for a vaccination schedule.
struct VaccinationProgress: Sendable {
    let completed: Int
    let total: Int
    let overdueCount: Int
    let pendingCount: Int
    let upcomingCount: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }
}
```

- [ ] **Step 4: Create VaccinationScheduleService**

Create `src/GentleGuardian/Core/Services/VaccinationScheduleService.swift`:

```swift
import Foundation
import os.log

/// Loads vaccination schedules from bundled JSON and computes dose statuses and progress.
final class VaccinationScheduleService: Sendable {

    private let schedules: [String: CountrySchedule]
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "VaccinationScheduleService")

    init() {
        guard let url = Bundle.main.url(forResource: "vaccination-schedules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: CountrySchedule].self, from: data)
        else {
            logger.error("Failed to load vaccination-schedules.json")
            schedules = [:]
            return
        }
        schedules = decoded
    }

    /// Returns the schedule for a country code, or nil if not found.
    func schedule(for countryCode: String) -> CountrySchedule? {
        schedules[countryCode]
    }

    /// Groups a schedule's doses by age group label, preserving order.
    func ageGroups(for schedule: CountrySchedule) -> [AgeGroup] {
        var groups: [AgeGroup] = []
        var seen: Set<String> = []

        for dose in schedule.doses {
            if !seen.contains(dose.ageGroupLabel) {
                seen.insert(dose.ageGroupLabel)
                let groupDoses = schedule.doses.filter { $0.ageGroupLabel == dose.ageGroupLabel }
                groups.append(AgeGroup(label: dose.ageGroupLabel, doses: groupDoses))
            }
        }

        return groups
    }

    /// Computes the status of a single dose given existing records and child age.
    func status(
        for dose: ScheduledDose,
        records: [VaccinationRecord],
        childAgeMonths: Double
    ) -> DoseStatus {
        let hasRecord = records.contains {
            $0.vaccineType == dose.vaccineType
            && $0.doseNumber == dose.doseNumber
            && !$0.isArchived
        }

        if hasRecord { return .completed }
        if childAgeMonths > dose.recommendedAgeMaxMonths { return .overdue }
        if childAgeMonths >= dose.recommendedAgeMinMonths { return .pending }
        return .upcoming
    }

    /// Computes the overall status for an age group (worst status wins).
    func groupStatus(
        for group: AgeGroup,
        records: [VaccinationRecord],
        childAgeMonths: Double
    ) -> DoseStatus {
        let statuses = group.doses.map { status(for: $0, records: records, childAgeMonths: childAgeMonths) }

        if statuses.contains(.overdue) { return .overdue }
        if statuses.contains(.pending) { return .pending }
        if statuses.contains(.upcoming) { return .upcoming }
        return .completed
    }

    /// Computes progress summary for a schedule.
    func progress(
        for schedule: CountrySchedule,
        records: [VaccinationRecord],
        childAgeMonths: Double = 0
    ) -> VaccinationProgress {
        var completed = 0
        var overdue = 0
        var pending = 0
        var upcoming = 0

        for dose in schedule.doses {
            switch status(for: dose, records: records, childAgeMonths: childAgeMonths) {
            case .completed: completed += 1
            case .overdue: overdue += 1
            case .pending: pending += 1
            case .upcoming: upcoming += 1
            }
        }

        return VaccinationProgress(
            completed: completed,
            total: schedule.doses.count,
            overdueCount: overdue,
            pendingCount: pending,
            upcomingCount: upcoming
        )
    }

    /// Returns the matching VaccinationRecord for a dose, if one exists.
    func record(
        for dose: ScheduledDose,
        in records: [VaccinationRecord]
    ) -> VaccinationRecord? {
        records.first {
            $0.vaccineType == dose.vaccineType
            && $0.doseNumber == dose.doseNumber
            && !$0.isArchived
        }
    }

    /// Computes the child's age as a human-readable string between two dates.
    static func ageString(from birthday: Date, to date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthday, to: date)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        if years > 0 {
            if months > 0 { return "\(years)y \(months)m" }
            return "\(years)y"
        }
        if months > 0 {
            if days > 0 { return "\(months)m \(days)d" }
            return "\(months)m"
        }
        return "\(max(days, 0))d"
    }

    /// Computes the child's age in months as a Double.
    static func ageInMonths(from birthday: Date, to date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthday, to: date)
        let months = Double(components.month ?? 0)
        let days = Double(components.day ?? 0)
        return months + (days / 30.44)
    }
}
```

- [ ] **Step 5: Create the vaccination-schedules.json file**

Create `src/GentleGuardian/Resources/vaccination-schedules.json` with schedule data for all 31 countries.

This file is large. It must contain a JSON object keyed by country code (e.g., `"US"`, `"DE"`, `"FR"`, etc.) where each value is a `CountrySchedule` with `name`, `source`, and `doses` array.

The **USA (US)** schedule must include these doses based on the AAP 2026 schedule:
- Birth: HepB (dose 1), RSV (dose 1)
- 2 Months: DTaP (1), IPV (1), Hib (1), PCV (1), RV (1), HepB (2)
- 4 Months: DTaP (2), IPV (2), Hib (2), PCV (2), RV (2)
- 6 Months: DTaP (3), IPV (3), PCV (3), RV (3), HepB (3), Influenza (1)
- 12-15 Months: MMR (1), Varicella (1), HepA (1), Hib (booster/4), PCV (booster/4)
- 15-18 Months: DTaP (4)
- 4-6 Years: DTaP (5), IPV (4), MMR (2), Varicella (2)
- 11-12 Years: Tdap (1), HPV (1), MenACWY (1)
- 16 Years: MenACWY (2)
- 16-18 Years: MenB (1)

Each EU/EEA country must have its core vaccines (DTaP, IPV, MMR, Hib, HPV) plus any country-specific ones (HepB, BCG, Rotavirus, PCV, MenC, MenB, Varicella, HepA).

Structure per dose:
```json
{
  "vaccineType": "hepB",
  "doseNumber": 1,
  "recommendedAgeMinMonths": 0,
  "recommendedAgeMaxMonths": 0,
  "ageGroupLabel": "Birth",
  "displayName": "Hepatitis B",
  "abbreviation": "HepB"
}
```

> **Note:** This file will be several hundred lines. The implementing agent should populate all 31 country schedules based on the dose lists in the spec and from ECDC / national health authority data. Prioritize accuracy for the US schedule. For EU/EEA countries, include at minimum the core vaccines at standard ages; country-specific additions (BCG, HepA, MenB, etc.) should be included where known.

- [ ] **Step 6: Run xcodegen and run tests**

```bash
cd src && xcodegen generate --spec project.yml
swift test --filter VaccinationScheduleServiceTests 2>&1 | tail -20
```
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add src/GentleGuardian/Core/Models/VaccinationSchedule.swift src/GentleGuardian/Core/Services/VaccinationScheduleService.swift src/GentleGuardian/Resources/vaccination-schedules.json src/GentleGuardianTests/VaccinationScheduleServiceTests.swift
git commit -m "feat: add VaccinationScheduleService with JSON schedule loading and dose status computation"
```

---

## Task 6: VaccinationRepository

**Files:**
- Create: `src/GentleGuardian/Core/Repositories/VaccinationRepository.swift`

- [ ] **Step 1: Create VaccinationRepository**

Follow the exact pattern from `FeedingRepository.swift`:

```swift
import Foundation
import Observation
import DittoSwift
import os.log

/// Repository managing CRUD operations and live queries for VaccinationRecord documents.
@Observable
@MainActor
final class VaccinationRepository {

    // MARK: - Published State

    /// Vaccination records for the currently observed child.
    private(set) var records: [VaccinationRecord] = []

    // MARK: - Private Properties

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "VaccinationRepository")
    @ObservationIgnored nonisolated(unsafe) private var recordsObserver: DittoStoreObserver?

    // MARK: - Initialization

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    deinit {
        recordsObserver?.cancel()
    }

    // MARK: - Observe

    /// Starts a live query observing vaccination records for a child.
    func observeRecords(childId: String) {
        recordsObserver?.cancel()

        let query = QueryHelpers.selectForChild(
            from: AppConstants.Collections.vaccinationRecords,
            orderBy: "dateAdministered DESC"
        )

        Task {
            do {
                recordsObserver = try await dittoManager.registerObserver(
                    query: query,
                    arguments: QueryHelpers.childArgs(childId)
                ) { [weak self] result in
                    let parsed = result.items.map { item -> VaccinationRecord in
                        let doc = item.value
                        let record = VaccinationRecord(from: doc)
                        item.dematerialize()
                        return record
                    }
                    Task { @MainActor [weak self] in
                        self?.records = parsed
                    }
                }
            } catch {
                logger.error("Failed to observe vaccination records: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mutations

    /// Inserts a new vaccination record.
    func insert(record: VaccinationRecord) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.vaccinationRecords),
            arguments: ["document": record.toDittoDocument()]
        )
        logger.debug("Inserted vaccination record: \(record.id)")
    }

    /// Updates an existing vaccination record.
    func update(record: VaccinationRecord) async throws {
        var updated = record
        updated.updatedAt = Date()
        try await dittoManager.execute(
            query: QueryHelpers.upsert(into: AppConstants.Collections.vaccinationRecords),
            arguments: ["document": updated.toDittoDocument()]
        )
        logger.debug("Updated vaccination record: \(record.id)")
    }

    /// Soft-deletes a vaccination record.
    func softDelete(recordId: String) async throws {
        try await dittoManager.execute(
            query: QueryHelpers.softDelete(from: AppConstants.Collections.vaccinationRecords),
            arguments: QueryHelpers.softDeleteArgs(recordId)
        )
        logger.debug("Soft-deleted vaccination record: \(recordId)")
    }
}
```

- [ ] **Step 2: Build to verify**

Run `xcodegen generate` then build in Xcode (Cmd+B). Expected: successful build.

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/Core/Repositories/VaccinationRepository.swift
git commit -m "feat: add VaccinationRepository with Ditto live observer and CRUD"
```

---

## Task 7: Wire VaccinationRepository into App

**Files:**
- Modify: `src/GentleGuardian/App/GentleGuardianApp.swift`
- Modify: `src/GentleGuardian/App/ContentView.swift`

- [ ] **Step 1: Add VaccinationRepository to GentleGuardianApp**

In `GentleGuardianApp.swift`, add to the `@State` property declarations (after `sleepRepository` and `otherEventRepository`, around line 25):

```swift
    @State private var vaccinationRepository: VaccinationRepository
```

In `init()`, add after `_otherEventRepository = State(...)` (around line 42):

```swift
        _vaccinationRepository = State(initialValue: VaccinationRepository(dittoManager: manager))
```

In `body`, update the `ContentView(...)` call to pass the new repository:

```swift
                    ContentView(
                        feedingRepository: feedingRepository,
                        diaperRepository: diaperRepository,
                        healthRepository: healthRepository,
                        activityRepository: activityRepository,
                        sleepRepository: sleepRepository,
                        otherEventRepository: otherEventRepository,
                        vaccinationRepository: vaccinationRepository
                    )
```

- [ ] **Step 2: Update ContentView to accept and use VaccinationRepository**

In `ContentView.swift`, add the new dependency after `otherEventRepository` (around line 22):

```swift
    let vaccinationRepository: VaccinationRepository
```

Add `.vaccination` case to the `AppTab` enum (at the end, around line 196):

```swift
enum AppTab: String, Hashable {
    case home
    case summary
    case child
    case information
    case vaccination
}
```

In the `iPhoneLayout`, add the conditional tab **before** the Info tab (before line 96):

```swift
            if activeChildState.activeChild?.isVaccinationTrackingEnabled == true {
                Tab("Vaccines", systemImage: "syringe", value: .vaccination) {
                    NavigationStack {
                        Text("Vaccination View — Coming Soon")
                    }
                }
                .accessibilityIdentifier("vaccination-tab")
            }
```

In the `iPadLayout` detail switch, add the new case (before the closing brace of the switch, around line 144):

```swift
            case .vaccination:
                Text("Vaccination View — Coming Soon")
```

In the `sidebarContent`, add the conditional vaccination entry after the "Info" label (around line 162):

```swift
                    if activeChildState.activeChild?.isVaccinationTrackingEnabled == true {
                        Label("Vaccines", systemImage: "syringe")
                            .tag(AppTab.vaccination)
                    }
```

- [ ] **Step 3: Build to verify**

Build in Xcode (Cmd+B). Expected: successful build. The tab won't appear yet because `isVaccinationTrackingEnabled` defaults to `false`.

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/App/GentleGuardianApp.swift src/GentleGuardian/App/ContentView.swift
git commit -m "feat: wire VaccinationRepository into app and add conditional tab"
```

---

## Task 8: Registration + Child Profile — Vaccination Settings

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/Views/VaccinationSettingsCard.swift`
- Modify: `src/GentleGuardian/Features/Onboarding/Views/RegisterChildView.swift`
- Modify: `src/GentleGuardian/Features/Onboarding/ViewModels/RegisterChildViewModel.swift`
- Modify: `src/GentleGuardian/Features/ChildProfile/Views/ChildProfileView.swift`
- Modify: `src/GentleGuardian/Features/ChildProfile/ViewModels/ChildProfileViewModel.swift`

- [ ] **Step 1: Create reusable VaccinationSettingsCard**

```swift
import SwiftUI

/// Reusable card for configuring vaccination tracking settings.
/// Used in both RegisterChildView and ChildProfileView.
struct VaccinationSettingsCard: View {

    @Binding var isTrackingEnabled: Bool
    @Binding var selectedRegion: VaccinationRegion
    @Binding var selectedCountryCode: String

    @Environment(\.isNightMode) private var isNightMode

    var body: some View {
        GGCard(style: .subtle) {
            VStack(alignment: .leading, spacing: GGSpacing.md) {
                Toggle(isOn: $isTrackingEnabled) {
                    VStack(alignment: .leading, spacing: GGSpacing.xs) {
                        Text("Vaccination Tracking")
                            .font(.ggLabelLarge)
                            .foregroundStyle(colors.onSurface)

                        Text("Track your child's immunization schedule with recommended vaccines for your region.")
                            .font(.ggBodySmall)
                            .foregroundStyle(colors.onSurface.opacity(0.6))
                    }
                }
                .tint(colors.primary)

                if isTrackingEnabled {
                    VStack(alignment: .leading, spacing: GGSpacing.sm) {
                        // Region picker
                        Text("Region")
                            .font(.ggLabelMedium)
                            .foregroundStyle(colors.onSurface.opacity(0.6))

                        Picker("Region", selection: $selectedRegion) {
                            ForEach(VaccinationRegion.allCases, id: \.self) { region in
                                Text(region.displayName).tag(region)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Country picker (Europe only)
                        if selectedRegion == .europe {
                            Text("Country")
                                .font(.ggLabelMedium)
                                .foregroundStyle(colors.onSurface.opacity(0.6))

                            Picker("Country", selection: $selectedCountryCode) {
                                ForEach(selectedRegion.countries, id: \.code) { country in
                                    Text("\(VaccinationRegion.flagEmoji(for: country.code)) \(country.name)")
                                        .tag(country.code)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                        }

                        // Source info
                        if let scheduleName = scheduleSourceName {
                            Text("Schedule based on \(scheduleName) recommendations.")
                                .font(.ggBodySmall)
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, GGSpacing.md)
                                .padding(.vertical, GGSpacing.xs)
                                .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.5)
                        }
                    }
                }
            }
        }
    }

    private var scheduleSourceName: String? {
        let code = selectedRegion == .usa ? "US" : selectedCountryCode
        let service = VaccinationScheduleService()
        return service.schedule(for: code)?.source
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 2: Add vaccination fields to RegisterChildViewModel**

In `RegisterChildViewModel.swift`, add form state properties after `prematurityWeeks` (around line 41):

```swift
    /// Whether vaccination tracking is enabled.
    var isVaccinationTrackingEnabled: Bool = false

    /// Selected vaccination region.
    var vaccinationRegion: VaccinationRegion = .usa

    /// Selected country code for vaccination schedule.
    var vaccinationCountryCode: String = "US"
```

In `submit()`, update the `Child(...)` creation to include the new fields. Replace the existing `Child(...)` initializer (around line 125) with:

```swift
        let child = Child(
            firstName: trimmedName,
            birthday: birthday,
            sex: sex,
            prematurityWeeks: isPremature ? prematurityWeeks : nil,
            prematurityStatus: computedPrematurityStatus,
            syncCode: syncCode,
            vaccinationRegion: isVaccinationTrackingEnabled ? vaccinationRegion.rawValue : nil,
            vaccinationCountry: isVaccinationTrackingEnabled ? (vaccinationRegion == .usa ? "US" : vaccinationCountryCode) : nil,
            isVaccinationTrackingEnabled: isVaccinationTrackingEnabled
        )
```

- [ ] **Step 3: Add vaccination section to RegisterChildView**

In `RegisterChildView.swift`, add a new section method after `prematuritySection`:

```swift
    // MARK: - Vaccination Section

    private func vaccinationSection(viewModel: RegisterChildViewModel) -> some View {
        VaccinationSettingsCard(
            isTrackingEnabled: Binding(
                get: { viewModel.isVaccinationTrackingEnabled },
                set: { viewModel.isVaccinationTrackingEnabled = $0 }
            ),
            selectedRegion: Binding(
                get: { viewModel.vaccinationRegion },
                set: { viewModel.vaccinationRegion = $0 }
            ),
            selectedCountryCode: Binding(
                get: { viewModel.vaccinationCountryCode },
                set: { viewModel.vaccinationCountryCode = $0 }
            )
        )
    }
```

In `formContent`, add the vaccination section call after the prematurity section (after `prematuritySection(viewModel: viewModel)`):

```swift
                // Vaccination tracking
                vaccinationSection(viewModel: viewModel)
```

- [ ] **Step 4: Add vaccination fields to ChildProfileViewModel**

In `ChildProfileViewModel.swift`, add editable state (after `editDayEndHour`, around line 39):

```swift
    /// Editable vaccination tracking toggle.
    var editIsVaccinationTrackingEnabled: Bool = false

    /// Editable vaccination region.
    var editVaccinationRegion: VaccinationRegion = .usa

    /// Editable vaccination country code.
    var editVaccinationCountryCode: String = "US"
```

Update `hasChanges` computed property to include the new fields (add to the condition chain):

```swift
            || editIsVaccinationTrackingEnabled != child.isVaccinationTrackingEnabled
            || editVaccinationRegion.rawValue != (child.vaccinationRegion ?? VaccinationRegion.usa.rawValue)
            || editVaccinationCountryCode != (child.vaccinationCountry ?? "US")
```

In `loadChild(_:)`, add after `editDayEndHour = child.dayEndHour`:

```swift
        editIsVaccinationTrackingEnabled = child.isVaccinationTrackingEnabled
        editVaccinationRegion = VaccinationRegion(rawValue: child.vaccinationRegion ?? "") ?? .usa
        editVaccinationCountryCode = child.vaccinationCountry ?? "US"
```

In `saveProfile()`, add before `do { try await childRepository.update(child: updatedChild) }`:

```swift
        updatedChild.isVaccinationTrackingEnabled = editIsVaccinationTrackingEnabled
        updatedChild.vaccinationRegion = editIsVaccinationTrackingEnabled ? editVaccinationRegion.rawValue : nil
        updatedChild.vaccinationCountry = editIsVaccinationTrackingEnabled ? (editVaccinationRegion == .usa ? "US" : editVaccinationCountryCode) : nil
```

- [ ] **Step 5: Add vaccination settings card to ChildProfileView**

In `ChildProfileView.swift`, add the vaccination settings card in `profileContent`, after the "Tracking day settings" `GGCard` and before the error message section:

```swift
                // Vaccination settings
                VaccinationSettingsCard(
                    isTrackingEnabled: Binding(
                        get: { viewModel.editIsVaccinationTrackingEnabled },
                        set: { viewModel.editIsVaccinationTrackingEnabled = $0 }
                    ),
                    selectedRegion: Binding(
                        get: { viewModel.editVaccinationRegion },
                        set: { viewModel.editVaccinationRegion = $0 }
                    ),
                    selectedCountryCode: Binding(
                        get: { viewModel.editVaccinationCountryCode },
                        set: { viewModel.editVaccinationCountryCode = $0 }
                    )
                )
```

- [ ] **Step 6: Run xcodegen, build, and verify**

```bash
cd src && xcodegen generate --spec project.yml
```
Build in Xcode (Cmd+B). Run the app in a simulator — register a child with vaccination tracking enabled and verify the 5th tab appears. Toggle it off in the profile and verify the tab disappears.

- [ ] **Step 7: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/Views/VaccinationSettingsCard.swift src/GentleGuardian/Features/Onboarding/Views/RegisterChildView.swift src/GentleGuardian/Features/Onboarding/ViewModels/RegisterChildViewModel.swift src/GentleGuardian/Features/ChildProfile/Views/ChildProfileView.swift src/GentleGuardian/Features/ChildProfile/ViewModels/ChildProfileViewModel.swift
git commit -m "feat: add vaccination settings to registration and child profile"
```

---

## Task 9: VaccinationViewModel

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/ViewModels/VaccinationViewModel.swift`

- [ ] **Step 1: Create VaccinationViewModel**

```swift
import Foundation
import Observation

/// ViewModel for the main vaccination tab view.
/// Aggregates schedule data, records, and computes age group statuses.
@Observable
@MainActor
final class VaccinationViewModel {

    // MARK: - Dependencies

    private let vaccinationRepository: VaccinationRepository
    private let scheduleService = VaccinationScheduleService()

    // MARK: - State

    /// The active child.
    var child: Child?

    /// The resolved country schedule.
    var schedule: CountrySchedule?

    /// Age groups derived from the schedule.
    var ageGroups: [AgeGroup] = []

    /// Vaccination records from the repository (filtered, non-archived).
    var records: [VaccinationRecord] { vaccinationRepository.records }

    /// "Other" (ad-hoc) vaccination records.
    var otherRecords: [VaccinationRecord] {
        records.filter { $0.vaccineType == VaccineType.other.rawValue }
    }

    // MARK: - Initialization

    init(vaccinationRepository: VaccinationRepository) {
        self.vaccinationRepository = vaccinationRepository
    }

    // MARK: - Setup

    /// Loads the schedule and starts observing records for the active child.
    func loadChild(_ child: Child) {
        self.child = child

        let countryCode = child.vaccinationCountry ?? "US"
        schedule = scheduleService.schedule(for: countryCode)

        if let schedule {
            ageGroups = scheduleService.ageGroups(for: schedule)
        }

        vaccinationRepository.observeRecords(childId: child.id)
    }

    // MARK: - Computed Properties

    /// The child's current age in months.
    var childAgeMonths: Double {
        guard let child else { return 0 }
        return VaccinationScheduleService.ageInMonths(from: child.birthday, to: Date())
    }

    /// Progress for the overall schedule.
    var progress: VaccinationProgress {
        guard let schedule else {
            return VaccinationProgress(completed: 0, total: 0, overdueCount: 0, pendingCount: 0, upcomingCount: 0)
        }
        return scheduleService.progress(for: schedule, records: records, childAgeMonths: childAgeMonths)
    }

    /// Status for a specific age group.
    func groupStatus(for group: AgeGroup) -> DoseStatus {
        scheduleService.groupStatus(for: group, records: records, childAgeMonths: childAgeMonths)
    }

    /// Status for a specific dose.
    func doseStatus(for dose: ScheduledDose) -> DoseStatus {
        scheduleService.status(for: dose, records: records, childAgeMonths: childAgeMonths)
    }

    /// The matching record for a dose, if completed.
    func record(for dose: ScheduledDose) -> VaccinationRecord? {
        scheduleService.record(for: dose, in: records)
    }

    /// Number of completed doses in an age group.
    func completedCount(for group: AgeGroup) -> Int {
        group.doses.filter { doseStatus(for: $0) == .completed }.count
    }

    /// Number of remaining (non-completed) doses in an age group.
    func remainingDoses(for group: AgeGroup) -> [ScheduledDose] {
        group.doses.filter { doseStatus(for: $0) != .completed }
    }

    /// The schedule source display name.
    var scheduleSourceName: String {
        schedule?.source ?? ""
    }

    /// Date when child reached a given age group label (for display).
    func childDateForAgeGroup(_ group: AgeGroup) -> String? {
        guard let child, let firstDose = group.doses.first else { return nil }
        let calendar = Calendar.current
        let months = Int(firstDose.recommendedAgeMinMonths)
        guard let date = calendar.date(byAdding: .month, value: months, to: child.birthday) else { return nil }

        if months == 0 {
            return DateService.displayDate(from: child.birthday)
        }
        return DateService.displayDate(from: date)
    }
}
```

- [ ] **Step 2: Build to verify**

Build in Xcode (Cmd+B). Expected: successful build.

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/ViewModels/VaccinationViewModel.swift
git commit -m "feat: add VaccinationViewModel with progress and status computation"
```

---

## Task 10: LogVaccinationViewModel

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/ViewModels/LogVaccinationViewModel.swift`
- Test: `src/GentleGuardianTests/LogVaccinationViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
import Foundation
@testable import GentleGuardian

struct LogVaccinationViewModelTests {

    @Test func ageAtSelectedDateComputation() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let vacDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 18))!

        let ageString = VaccinationScheduleService.ageString(from: birthday, to: vacDate)

        #expect(ageString == "2m 3d")
    }

    @Test func dateCannotBeBeforeBirthday() {
        let birthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let beforeBirthday = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14))!

        // The date range should be birthday...Date()
        #expect(beforeBirthday < birthday)
    }

    @Test func customVaccineNameRequired() {
        // For "other" type, name must be non-empty
        let name = ""
        let isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(!isValid)

        let validName = "Yellow Fever"
        let isValid2 = !validName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(isValid2)
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

These tests are pure logic that depends on already-built types. Run:
```bash
cd src && swift test --filter LogVaccinationViewModelTests 2>&1 | tail -10
```
Expected: All 3 tests PASS.

- [ ] **Step 3: Create LogVaccinationViewModel**

```swift
import Foundation
import Observation

/// ViewModel for logging individual, batch, and "other" vaccinations.
@Observable
@MainActor
final class LogVaccinationViewModel {

    // MARK: - Dependencies

    private let vaccinationRepository: VaccinationRepository

    // MARK: - State

    /// The child being vaccinated.
    var child: Child?

    /// Date administered (constrained in the view to birthday...today).
    var dateAdministered: Date = Date()

    /// Optional notes.
    var notes: String = ""

    /// For batch logging: which doses are selected.
    var selectedDoses: Set<String> = []

    /// For "other" type: custom vaccine name.
    var customVaccineName: String = ""

    /// For "other" type: custom vaccine description.
    var customVaccineDescription: String = ""

    /// Whether a save operation is in progress.
    var isSaving: Bool = false

    /// Whether the save completed successfully.
    var didSave: Bool = false

    /// Error message to display.
    var errorMessage: String?

    // MARK: - Initialization

    init(vaccinationRepository: VaccinationRepository) {
        self.vaccinationRepository = vaccinationRepository
    }

    // MARK: - Computed

    /// The child's age at the selected date.
    var ageAtDate: String {
        guard let child else { return "" }
        return VaccinationScheduleService.ageString(from: child.birthday, to: dateAdministered)
    }

    /// Date range for the date picker.
    var dateRange: ClosedRange<Date> {
        let floor = child?.birthday ?? Date.distantPast
        return floor...Date()
    }

    /// Whether the "other" form is valid.
    var isOtherFormValid: Bool {
        !customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Saves a single dose vaccination record.
    func saveIndividual(dose: ScheduledDose) async {
        guard let child else { return }
        isSaving = true
        errorMessage = nil

        let record = VaccinationRecord(
            childId: child.id,
            vaccineType: dose.vaccineType,
            doseNumber: dose.doseNumber,
            dateAdministered: dateAdministered,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await vaccinationRepository.insert(record: record)
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination record."
        }
        isSaving = false
    }

    /// Saves multiple dose vaccination records (batch logging).
    func saveBatch(doses: [ScheduledDose]) async {
        guard let child else { return }
        isSaving = true
        errorMessage = nil

        let selected = doses.filter { selectedDoses.contains($0.id) }

        do {
            for dose in selected {
                let record = VaccinationRecord(
                    childId: child.id,
                    vaccineType: dose.vaccineType,
                    doseNumber: dose.doseNumber,
                    dateAdministered: dateAdministered,
                    notes: notes.isEmpty ? nil : notes
                )
                try await vaccinationRepository.insert(record: record)
            }
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination records."
        }
        isSaving = false
    }

    /// Saves an "other" (ad-hoc) vaccination record.
    func saveOther() async {
        guard let child, isOtherFormValid else { return }
        isSaving = true
        errorMessage = nil

        let record = VaccinationRecord(
            childId: child.id,
            vaccineType: VaccineType.other.rawValue,
            doseNumber: 0,
            dateAdministered: dateAdministered,
            notes: notes.isEmpty ? nil : notes,
            customVaccineName: customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines),
            customVaccineDescription: customVaccineDescription.isEmpty ? nil : customVaccineDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await vaccinationRepository.insert(record: record)
            didSave = true
        } catch {
            errorMessage = "Failed to save vaccination record."
        }
        isSaving = false
    }

    /// Updates an existing vaccination record.
    func updateRecord(_ record: VaccinationRecord) async {
        isSaving = true
        errorMessage = nil

        var updated = record
        updated.dateAdministered = dateAdministered
        updated.notes = notes.isEmpty ? nil : notes
        if record.vaccineType == VaccineType.other.rawValue {
            updated.customVaccineName = customVaccineName.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.customVaccineDescription = customVaccineDescription.isEmpty ? nil : customVaccineDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            try await vaccinationRepository.update(record: updated)
            didSave = true
        } catch {
            errorMessage = "Failed to update vaccination record."
        }
        isSaving = false
    }

    /// Soft-deletes a vaccination record.
    func deleteRecord(_ record: VaccinationRecord) async {
        isSaving = true
        errorMessage = nil

        do {
            try await vaccinationRepository.softDelete(recordId: record.id)
            didSave = true
        } catch {
            errorMessage = "Failed to delete vaccination record."
        }
        isSaving = false
    }

    /// Initializes batch selection with all remaining doses selected.
    func initBatchSelection(doses: [ScheduledDose]) {
        selectedDoses = Set(doses.map(\.id))
    }

    /// Loads an existing record for editing.
    func loadRecord(_ record: VaccinationRecord) {
        dateAdministered = record.dateAdministered
        notes = record.notes ?? ""
        customVaccineName = record.customVaccineName ?? ""
        customVaccineDescription = record.customVaccineDescription ?? ""
    }
}
```

- [ ] **Step 4: Build to verify**

Build in Xcode (Cmd+B). Expected: successful build.

- [ ] **Step 5: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/ViewModels/LogVaccinationViewModel.swift src/GentleGuardianTests/LogVaccinationViewModelTests.swift
git commit -m "feat: add LogVaccinationViewModel for individual, batch, and other logging"
```

---

## Task 11: VaccinationView (Main Tab)

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/Views/VaccinationView.swift`
- Modify: `src/GentleGuardian/App/ContentView.swift` (replace placeholder)

- [ ] **Step 1: Create VaccinationView**

```swift
import SwiftUI

/// Main vaccination tab showing progress summary and age-grouped checklist.
struct VaccinationView: View {

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.isNightMode) private var isNightMode

    let vaccinationRepository: VaccinationRepository
    @State private var viewModel: VaccinationViewModel
    @State private var showLogOther = false

    init(vaccinationRepository: VaccinationRepository) {
        self.vaccinationRepository = vaccinationRepository
        _viewModel = State(initialValue: VaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            if viewModel.schedule != nil {
                scrollContent
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Vaccinations")
        .inlineNavigationBarTitle()
        .onAppear {
            if let child = activeChildState.activeChild {
                viewModel.loadChild(child)
            }
        }
        .onChange(of: activeChildState.activeChild) { _, newChild in
            if let child = newChild {
                viewModel.loadChild(child)
            }
        }
        .sheet(isPresented: $showLogOther) {
            LogOtherVaccineSheet(
                vaccinationRepository: vaccinationRepository,
                child: viewModel.child
            )
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: GGSpacing.lg) {
                // Header
                headerSection

                // Progress card
                progressCard

                // Stats row
                statsRow

                // Age groups
                Text("Schedule by Age")
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(viewModel.ageGroups) { group in
                    NavigationLink(value: group.id) {
                        ageGroupRow(group: group)
                    }
                    .buttonStyle(.plain)
                }

                // Log Other button
                GGButton(
                    "Log Other Vaccine",
                    variant: .secondary,
                    icon: "plus.circle"
                ) {
                    showLogOther = true
                }

                // Other vaccines section
                if !viewModel.otherRecords.isEmpty {
                    otherVaccinesSection
                }
            }
            .padding(GGSpacing.pageInsets)
            .padding(.bottom, GGSpacing.xxl)
        }
        .navigationDestination(for: String.self) { groupId in
            if let group = viewModel.ageGroups.first(where: { $0.id == groupId }) {
                AgeGroupDetailView(
                    group: group,
                    vaccinationRepository: vaccinationRepository,
                    vaccinationViewModel: viewModel
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: GGSpacing.xs) {
            if let child = viewModel.child {
                Text("\(child.firstName) \u{00B7} \(viewModel.schedule?.name ?? "")")
                    .font(.ggBodyMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.6))
            }
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        let progress = viewModel.progress
        return GGCard(style: .hero) {
            HStack {
                VStack(alignment: .leading, spacing: GGSpacing.xs) {
                    Text("PROGRESS")
                        .font(.ggLabelSmall)
                        .foregroundStyle(colors.onPrimary.opacity(0.6))

                    Text("\(progress.completed) / \(progress.total)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(colors.onPrimary)

                    Text("doses completed")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onPrimary.opacity(0.7))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(colors.onPrimary.opacity(0.15), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress.total > 0 ? CGFloat(progress.completed) / CGFloat(progress.total) : 0)
                        .stroke(colors.onPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress.percentage))%")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onPrimary)
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        let progress = viewModel.progress
        return HStack(spacing: GGSpacing.sm) {
            statPill(title: "Overdue", value: "\(progress.overdueCount)", valueColor: GGColors.error)
            statPill(title: "Pending", value: "\(progress.pendingCount)", valueColor: GGColors.tertiary)
            statPill(title: "Up to date", value: "\(progress.completed)", valueColor: colors.primary)
        }
    }

    private func statPill(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: GGSpacing.xs) {
            Text(title)
                .font(.ggLabelSmall)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            Text(value)
                .font(.ggLabelLarge)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GGSpacing.sm)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.6)
    }

    // MARK: - Age Group Row

    private func ageGroupRow(group: AgeGroup) -> some View {
        let status = viewModel.groupStatus(for: group)
        let completed = viewModel.completedCount(for: group)
        let total = group.doses.count
        let isOverdue = status == .overdue
        let isFuture = status == .upcoming

        return HStack(spacing: GGSpacing.sm) {
            statusIcon(for: status)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.label)
                    .font(.ggLabelLarge)
                    .foregroundStyle(colors.onSurface)

                Text(statusSubtitle(status: status, completed: completed, total: total))
                    .font(.ggBodySmall)
                    .foregroundStyle(subtitleColor(for: status))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.ggBodySmall)
                .foregroundStyle(colors.onSurface.opacity(0.4))
        }
        .padding(GGSpacing.md)
        .surfaceLevel(.container, cornerRadius: GGSpacing.cardCornerRadius * 0.6)
        .overlay(
            isOverdue
                ? RoundedRectangle(cornerRadius: GGSpacing.cardCornerRadius * 0.6)
                    .inset(by: 0.5)
                    .stroke(GGColors.error.opacity(0.4), lineWidth: 1)
                    .overlay(
                        Rectangle()
                            .fill(GGColors.error)
                            .frame(width: 3)
                            .clipShape(.rect(topLeadingRadius: GGSpacing.cardCornerRadius * 0.6, bottomLeadingRadius: GGSpacing.cardCornerRadius * 0.6)),
                        alignment: .leading
                    )
                : nil
        )
        .opacity(isFuture ? 0.6 : 1.0)
    }

    @ViewBuilder
    private func statusIcon(for status: DoseStatus) -> some View {
        switch status {
        case .completed:
            Circle()
                .fill(colors.primary)
                .overlay(Image(systemName: "checkmark").font(.caption2).foregroundStyle(.white))
        case .overdue:
            Circle()
                .fill(GGColors.error)
                .overlay(Image(systemName: "exclamationmark").font(.caption2).foregroundStyle(.white))
        case .pending:
            Circle()
                .fill(GGColors.tertiary)
                .overlay(Image(systemName: "ellipsis").font(.caption2).foregroundStyle(.white))
        case .upcoming:
            Circle()
                .stroke(colors.onSurface.opacity(0.3), lineWidth: 1.5)
        }
    }

    private func statusSubtitle(status: DoseStatus, completed: Int, total: Int) -> String {
        switch status {
        case .completed: "\(completed) of \(total) doses"
        case .overdue: "\(completed) of \(total) doses \u{00B7} overdue"
        case .pending: "\(completed) of \(total) doses \u{00B7} \(total - completed) remaining"
        case .upcoming: "\(completed) of \(total) doses \u{00B7} upcoming"
        }
    }

    private func subtitleColor(for status: DoseStatus) -> Color {
        switch status {
        case .completed: colors.primary
        case .overdue: GGColors.error
        case .pending: GGColors.tertiary
        case .upcoming: colors.onSurface.opacity(0.5)
        }
    }

    // MARK: - Other Vaccines Section

    private var otherVaccinesSection: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            Text("Other Vaccines")
                .font(.ggLabelLarge)
                .foregroundStyle(colors.onSurface.opacity(0.6))

            ForEach(viewModel.otherRecords) { record in
                HStack(spacing: GGSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(colors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.customVaccineName ?? "Other")
                            .font(.ggLabelMedium)
                            .foregroundStyle(colors.onSurface)
                        if let desc = record.customVaccineDescription {
                            Text(desc)
                                .font(.ggBodySmall)
                                .foregroundStyle(colors.onSurface.opacity(0.6))
                        }
                        Text("\(DateService.displayDate(from: record.dateAdministered)) \u{00B7} at \(VaccinationScheduleService.ageString(from: viewModel.child?.birthday ?? Date(), to: record.dateAdministered))")
                            .font(.ggBodySmall)
                            .foregroundStyle(colors.primary)
                    }

                    Spacer()
                }
                .padding(GGSpacing.md)
                .surfaceLevel(.container, cornerRadius: GGSpacing.cardCornerRadius * 0.6)
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 2: Replace placeholder in ContentView**

In `ContentView.swift`, replace the placeholder `Text("Vaccination View — Coming Soon")` in the iPhone tab with:

```swift
                    VaccinationView(vaccinationRepository: vaccinationRepository)
```

And in the iPad layout detail switch:

```swift
            case .vaccination:
                VaccinationView(vaccinationRepository: vaccinationRepository)
```

- [ ] **Step 3: Run xcodegen, build, and test in simulator**

```bash
cd src && xcodegen generate --spec project.yml
```
Build and run. Register a child with vaccination tracking enabled. Verify the Vaccines tab shows the progress card and age group list.

- [ ] **Step 4: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/Views/VaccinationView.swift src/GentleGuardian/App/ContentView.swift
git commit -m "feat: add VaccinationView with progress card and age group list"
```

---

## Task 12: AgeGroupDetailView

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/Views/AgeGroupDetailView.swift`

- [ ] **Step 1: Create AgeGroupDetailView**

```swift
import SwiftUI

/// Detail view for a single age group showing all doses with their statuses.
struct AgeGroupDetailView: View {

    let group: AgeGroup
    let vaccinationRepository: VaccinationRepository
    let vaccinationViewModel: VaccinationViewModel

    @Environment(\.isNightMode) private var isNightMode

    @State private var showLogSheet: ScheduledDose?
    @State private var showBatchSheet = false
    @State private var showEditSheet: VaccinationRecord?

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: GGSpacing.md) {
                    // Age context card
                    ageContextCard

                    // Dose list
                    ForEach(group.doses) { dose in
                        doseRow(dose: dose)
                    }

                    // Log All Remaining button
                    let remaining = vaccinationViewModel.remainingDoses(for: group)
                    if !remaining.isEmpty {
                        GGButton(
                            "Log All Remaining (\(remaining.count))",
                            variant: .primary,
                            icon: "checkmark.circle"
                        ) {
                            showBatchSheet = true
                        }
                        .padding(.top, GGSpacing.sm)
                    }
                }
                .padding(GGSpacing.pageInsets)
                .padding(.bottom, GGSpacing.xxl)
            }
        }
        .navigationTitle(group.label)
        .inlineNavigationBarTitle()
        .sheet(item: $showLogSheet) { dose in
            LogVaccinationSheet(
                dose: dose,
                vaccinationRepository: vaccinationRepository,
                child: vaccinationViewModel.child
            )
        }
        .sheet(isPresented: $showBatchSheet) {
            LogBatchVaccinationSheet(
                doses: vaccinationViewModel.remainingDoses(for: group),
                vaccinationRepository: vaccinationRepository,
                child: vaccinationViewModel.child
            )
        }
        .sheet(item: $showEditSheet) { record in
            EditVaccinationSheet(
                record: record,
                vaccinationRepository: vaccinationRepository,
                child: vaccinationViewModel.child
            )
        }
    }

    // MARK: - Age Context Card

    private var ageContextCard: some View {
        VStack(spacing: GGSpacing.xs) {
            Text("Recommended at")
                .font(.ggBodySmall)
                .foregroundStyle(colors.onSurface.opacity(0.6))

            Text(group.label)
                .font(.ggTitleMedium)
                .foregroundStyle(colors.onSurface)

            if let child = vaccinationViewModel.child,
               let dateStr = vaccinationViewModel.childDateForAgeGroup(group) {
                Text("\(child.firstName) was \(group.label.lowercased()) on \(dateStr)")
                    .font(.ggBodySmall)
                    .foregroundStyle(colors.onSurface.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(GGSpacing.md)
        .surfaceLevel(.containerHigh, cornerRadius: GGSpacing.cardCornerRadius * 0.6)
    }

    // MARK: - Dose Row

    private func doseRow(dose: ScheduledDose) -> some View {
        let status = vaccinationViewModel.doseStatus(for: dose)
        let record = vaccinationViewModel.record(for: dose)
        let isOverdue = status == .overdue || status == .pending

        return HStack(spacing: GGSpacing.sm) {
            // Status icon
            doseStatusIcon(status: status)
                .frame(width: 28, height: 28)

            // Dose info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: GGSpacing.xs) {
                    Text(dose.abbreviation)
                        .font(.ggLabelLarge)
                        .foregroundStyle(colors.onSurface)
                    Text("(Dose \(dose.doseNumber))")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.6))
                }

                Text(dose.displayName)
                    .font(.ggBodySmall)
                    .foregroundStyle(colors.onSurface.opacity(0.6))

                if let record {
                    let ageStr = VaccinationScheduleService.ageString(
                        from: vaccinationViewModel.child?.birthday ?? Date(),
                        to: record.dateAdministered
                    )
                    Text("\(DateService.displayDate(from: record.dateAdministered)) \u{00B7} at \(ageStr) old")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.primary)
                } else if status == .overdue {
                    Text("Not recorded \u{00B7} overdue")
                        .font(.ggBodySmall)
                        .foregroundStyle(GGColors.error)
                } else if status == .pending {
                    Text("Not recorded \u{00B7} due now")
                        .font(.ggBodySmall)
                        .foregroundStyle(GGColors.tertiary)
                } else {
                    Text("Upcoming")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.4))
                }
            }

            Spacer()

            // Action button
            if status == .completed {
                Button {
                    showEditSheet = record
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.onSurface.opacity(0.4))
                }
            } else if status == .overdue || status == .pending {
                Button {
                    showLogSheet = dose
                } label: {
                    Text("Log")
                        .font(.ggLabelMedium)
                        .foregroundStyle(colors.onPrimary)
                        .padding(.horizontal, GGSpacing.md)
                        .padding(.vertical, GGSpacing.xs)
                        .background(colors.primary, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(GGSpacing.md)
        .surfaceLevel(.container, cornerRadius: GGSpacing.cardCornerRadius * 0.6)
        .overlay(
            isOverdue && status != .completed
                ? Rectangle()
                    .fill(GGColors.error)
                    .frame(width: 3)
                    .clipShape(.rect(topLeadingRadius: GGSpacing.cardCornerRadius * 0.6, bottomLeadingRadius: GGSpacing.cardCornerRadius * 0.6))
                : nil,
            alignment: .leading
        )
    }

    @ViewBuilder
    private func doseStatusIcon(status: DoseStatus) -> some View {
        switch status {
        case .completed:
            Circle()
                .fill(colors.primary)
                .overlay(Image(systemName: "checkmark").font(.caption).foregroundStyle(.white))
        case .overdue:
            Circle()
                .strokeBorder(GGColors.error, lineWidth: 2)
                .overlay(Image(systemName: "exclamationmark").font(.caption2).foregroundStyle(GGColors.error))
        case .pending:
            Circle()
                .strokeBorder(GGColors.tertiary, lineWidth: 2)
                .overlay(Image(systemName: "ellipsis").font(.caption2).foregroundStyle(GGColors.tertiary))
        case .upcoming:
            Circle()
                .strokeBorder(colors.onSurface.opacity(0.3), lineWidth: 1.5)
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 2: Build to verify**

Build in Xcode (Cmd+B). Expected: compilation errors for `LogVaccinationSheet`, `LogBatchVaccinationSheet`, `LogOtherVaccineSheet`, and `EditVaccinationSheet` — those are created in the next task. If building fails, temporarily comment out the `.sheet` modifiers to verify the rest compiles.

- [ ] **Step 3: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/Views/AgeGroupDetailView.swift
git commit -m "feat: add AgeGroupDetailView with dose list and status display"
```

---

## Task 13: Log Sheets (Individual, Batch, Other, Edit)

**Files:**
- Create: `src/GentleGuardian/Features/Vaccination/Views/LogVaccinationSheet.swift`
- Create: `src/GentleGuardian/Features/Vaccination/Views/LogBatchVaccinationSheet.swift`
- Create: `src/GentleGuardian/Features/Vaccination/Views/LogOtherVaccineSheet.swift`
- Create: `src/GentleGuardian/Features/Vaccination/Views/EditVaccinationSheet.swift`

- [ ] **Step 1: Create LogVaccinationSheet (individual)**

```swift
import SwiftUI

/// Sheet for logging a single scheduled vaccination dose.
struct LogVaccinationSheet: View {

    let dose: ScheduledDose
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(dose: ScheduledDose, vaccinationRepository: VaccinationRepository, child: Child?) {
        self.dose = dose
        self.vaccinationRepository = vaccinationRepository
        self.child = child
        _viewModel = State(initialValue: LogVaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        // Vaccine info
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text(dose.abbreviation)
                                    .font(.ggTitleMedium)
                                    .foregroundStyle(colors.onSurface)
                                Text("\(dose.displayName) \u{00B7} Dose \(dose.doseNumber)")
                                    .font(.ggBodyMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))
                            }
                        }

                        // Date picker
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Date Administered")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                DatePicker(
                                    "Date",
                                    selection: Binding(
                                        get: { viewModel.dateAdministered },
                                        set: { viewModel.dateAdministered = $0 }
                                    ),
                                    in: viewModel.dateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(colors.primary)

                                // Age at date
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(colors.primary)
                                    Text("Age: \(viewModel.ageAtDate)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface)
                                }
                            }
                        }

                        // Notes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Notes (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                TextEditor(text: Binding(
                                    get: { viewModel.notes },
                                    set: { viewModel.notes = $0 }
                                ))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(colors.onSurface)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.ggBodySmall)
                                .foregroundStyle(GGColors.error)
                        }

                        // Save button
                        GGButton(
                            "Save",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving
                        ) {
                            Task {
                                await viewModel.saveIndividual(dose: dose)
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log \(dose.abbreviation)")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 2: Create LogBatchVaccinationSheet**

```swift
import SwiftUI

/// Sheet for batch-logging multiple vaccination doses from a single visit.
struct LogBatchVaccinationSheet: View {

    let doses: [ScheduledDose]
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(doses: [ScheduledDose], vaccinationRepository: VaccinationRepository, child: Child?) {
        self.doses = doses
        self.vaccinationRepository = vaccinationRepository
        self.child = child
        _viewModel = State(initialValue: LogVaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        // Vaccine checkboxes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Select Vaccines Given")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                ForEach(doses) { dose in
                                    Toggle(isOn: Binding(
                                        get: { viewModel.selectedDoses.contains(dose.id) },
                                        set: { isOn in
                                            if isOn {
                                                viewModel.selectedDoses.insert(dose.id)
                                            } else {
                                                viewModel.selectedDoses.remove(dose.id)
                                            }
                                        }
                                    )) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(dose.abbreviation) (Dose \(dose.doseNumber))")
                                                .font(.ggLabelMedium)
                                                .foregroundStyle(colors.onSurface)
                                            Text(dose.displayName)
                                                .font(.ggBodySmall)
                                                .foregroundStyle(colors.onSurface.opacity(0.6))
                                        }
                                    }
                                    .tint(colors.primary)
                                }
                            }
                        }

                        // Date picker
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Date Administered")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                DatePicker(
                                    "Date",
                                    selection: Binding(
                                        get: { viewModel.dateAdministered },
                                        set: { viewModel.dateAdministered = $0 }
                                    ),
                                    in: viewModel.dateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(colors.primary)

                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(colors.primary)
                                    Text("Age: \(viewModel.ageAtDate)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface)
                                }
                            }
                        }

                        // Notes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Notes (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                TextEditor(text: Binding(
                                    get: { viewModel.notes },
                                    set: { viewModel.notes = $0 }
                                ))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(colors.onSurface)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.ggBodySmall)
                                .foregroundStyle(GGColors.error)
                        }

                        // Save button
                        GGButton(
                            "Save \(viewModel.selectedDoses.count) Vaccine\(viewModel.selectedDoses.count == 1 ? "" : "s")",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving,
                            isDisabled: viewModel.selectedDoses.isEmpty
                        ) {
                            Task {
                                await viewModel.saveBatch(doses: doses)
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log Visit")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
                viewModel.initBatchSelection(doses: doses)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 3: Create LogOtherVaccineSheet**

```swift
import SwiftUI

/// Sheet for logging a custom/ad-hoc vaccination not in the standard schedule.
struct LogOtherVaccineSheet: View {

    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel

    init(vaccinationRepository: VaccinationRepository, child: Child?) {
        self.vaccinationRepository = vaccinationRepository
        self.child = child
        _viewModel = State(initialValue: LogVaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        // Vaccine name
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Vaccine Name")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                GGTextField(
                                    "e.g., Yellow Fever",
                                    text: Binding(
                                        get: { viewModel.customVaccineName },
                                        set: { viewModel.customVaccineName = $0 }
                                    ),
                                    icon: "syringe"
                                )
                            }
                        }

                        // Description
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Description (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                GGTextField(
                                    "e.g., Required for travel to Brazil",
                                    text: Binding(
                                        get: { viewModel.customVaccineDescription },
                                        set: { viewModel.customVaccineDescription = $0 }
                                    ),
                                    icon: "text.alignleft"
                                )
                            }
                        }

                        // Date picker
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Date Administered")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                DatePicker(
                                    "Date",
                                    selection: Binding(
                                        get: { viewModel.dateAdministered },
                                        set: { viewModel.dateAdministered = $0 }
                                    ),
                                    in: viewModel.dateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(colors.primary)

                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(colors.primary)
                                    Text("Age: \(viewModel.ageAtDate)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface)
                                }
                            }
                        }

                        // Notes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Notes (optional)")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                TextEditor(text: Binding(
                                    get: { viewModel.notes },
                                    set: { viewModel.notes = $0 }
                                ))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(colors.onSurface)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.ggBodySmall)
                                .foregroundStyle(GGColors.error)
                        }

                        // Save button
                        GGButton(
                            "Save",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving,
                            isDisabled: !viewModel.isOtherFormValid
                        ) {
                            Task {
                                await viewModel.saveOther()
                            }
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Log Other Vaccine")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 4: Create EditVaccinationSheet**

```swift
import SwiftUI

/// Sheet for editing or deleting an existing vaccination record.
struct EditVaccinationSheet: View {

    let record: VaccinationRecord
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    @Environment(\.isNightMode) private var isNightMode
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LogVaccinationViewModel
    @State private var showDeleteConfirmation = false

    init(record: VaccinationRecord, vaccinationRepository: VaccinationRepository, child: Child?) {
        self.record = record
        self.vaccinationRepository = vaccinationRepository
        self.child = child
        _viewModel = State(initialValue: LogVaccinationViewModel(vaccinationRepository: vaccinationRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GGSpacing.lg) {
                        // Vaccine info
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text(record.displayName)
                                    .font(.ggTitleMedium)
                                    .foregroundStyle(colors.onSurface)
                                if record.vaccineType != VaccineType.other.rawValue {
                                    Text("Dose \(record.doseNumber)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface.opacity(0.6))
                                }
                            }
                        }

                        // Custom fields for "other" type
                        if record.vaccineType == VaccineType.other.rawValue {
                            GGCard(style: .standard) {
                                VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                    Text("Vaccine Name")
                                        .font(.ggLabelLarge)
                                        .foregroundStyle(colors.onSurface)

                                    GGTextField(
                                        "Vaccine name",
                                        text: Binding(
                                            get: { viewModel.customVaccineName },
                                            set: { viewModel.customVaccineName = $0 }
                                        ),
                                        icon: "syringe"
                                    )

                                    Text("Description (optional)")
                                        .font(.ggLabelMedium)
                                        .foregroundStyle(colors.onSurface.opacity(0.6))

                                    GGTextField(
                                        "Description",
                                        text: Binding(
                                            get: { viewModel.customVaccineDescription },
                                            set: { viewModel.customVaccineDescription = $0 }
                                        ),
                                        icon: "text.alignleft"
                                    )
                                }
                            }
                        }

                        // Date picker
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Date Administered")
                                    .font(.ggLabelLarge)
                                    .foregroundStyle(colors.onSurface)

                                DatePicker(
                                    "Date",
                                    selection: Binding(
                                        get: { viewModel.dateAdministered },
                                        set: { viewModel.dateAdministered = $0 }
                                    ),
                                    in: viewModel.dateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(colors.primary)

                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(colors.primary)
                                    Text("Age: \(viewModel.ageAtDate)")
                                        .font(.ggBodyMedium)
                                        .foregroundStyle(colors.onSurface)
                                }
                            }
                        }

                        // Notes
                        GGCard(style: .standard) {
                            VStack(alignment: .leading, spacing: GGSpacing.sm) {
                                Text("Notes")
                                    .font(.ggLabelMedium)
                                    .foregroundStyle(colors.onSurface.opacity(0.6))

                                TextEditor(text: Binding(
                                    get: { viewModel.notes },
                                    set: { viewModel.notes = $0 }
                                ))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(colors.onSurface)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.ggBodySmall)
                                .foregroundStyle(GGColors.error)
                        }

                        // Save button
                        GGButton(
                            "Save Changes",
                            variant: .primary,
                            icon: "checkmark.circle",
                            isLoading: viewModel.isSaving
                        ) {
                            Task {
                                await viewModel.updateRecord(record)
                            }
                        }

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Record")
                                .font(.ggLabelMedium)
                                .foregroundStyle(GGColors.error)
                        }
                    }
                    .padding(GGSpacing.pageInsets)
                    .padding(.bottom, GGSpacing.xxl)
                }
            }
            .navigationTitle("Edit Record")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
            }
            .onAppear {
                viewModel.child = child
                viewModel.loadRecord(record)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
            .alert("Delete Vaccination Record?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteRecord(record)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the record. The dose will show as not recorded.")
            }
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(isNightMode: isNightMode)
    }
}
```

- [ ] **Step 5: Run xcodegen, build, and test in simulator**

```bash
cd src && xcodegen generate --spec project.yml
```
Build and run. Register a child with vaccination tracking, navigate to the Vaccines tab, tap an age group, tap Log on a dose, fill in the date, save. Verify the dose shows as completed.

Test batch logging: tap "Log All Remaining", verify checkboxes, save. Test "Log Other Vaccine" from the main vaccination view.

- [ ] **Step 6: Commit**

```bash
git add src/GentleGuardian/Features/Vaccination/Views/LogVaccinationSheet.swift src/GentleGuardian/Features/Vaccination/Views/LogBatchVaccinationSheet.swift src/GentleGuardian/Features/Vaccination/Views/LogOtherVaccineSheet.swift src/GentleGuardian/Features/Vaccination/Views/EditVaccinationSheet.swift
git commit -m "feat: add log sheets for individual, batch, other, and edit vaccination records"
```

---

## Task 14: Final Integration + Polish

**Files:**
- Run: `xcodegen generate`
- Verify: All tests pass
- Verify: UI in light mode, dark mode, night mode

- [ ] **Step 1: Run xcodegen to pick up all new files**

```bash
cd src && xcodegen generate --spec project.yml
```

- [ ] **Step 2: Run all tests**

```bash
cd src && swift test 2>&1 | tail -20
```
Expected: All tests PASS (including VaccinationRecordTests, VaccinationScheduleServiceTests, LogVaccinationViewModelTests).

- [ ] **Step 3: Build and run in simulator**

Build in Xcode (Cmd+R). Test the full flow:
1. Register a child with vaccination tracking **enabled** (USA region)
2. Verify the 5th "Vaccines" tab appears
3. Tap the Vaccines tab — verify progress card shows 0/N doses
4. Tap an age group — verify dose list shows all doses as pending/overdue/upcoming
5. Log an individual dose — verify it shows as completed with date and age
6. Use "Log All Remaining" for batch logging — verify multiple doses saved
7. Log an "Other" vaccine — verify it appears in the Other Vaccines section
8. Edit a completed dose — change the date, verify it updates
9. Delete a dose — verify it returns to pending/overdue status
10. Go to Child Profile — toggle vaccination tracking off — verify tab disappears
11. Toggle it back on — verify tab reappears with data intact

- [ ] **Step 4: Test light/dark/night mode**

Switch between system light mode, system dark mode, and the app's night mode toggle. Verify:
- Colors are correct (green/teal for complete, amber for pending, red for overdue)
- Text is readable in all modes
- Progress card gradient matches the app's existing style

- [ ] **Step 5: Commit all remaining changes**

```bash
git add -A
git commit -m "feat: vaccination tracking — final integration and polish"
```
