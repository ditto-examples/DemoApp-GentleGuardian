import Foundation
import DittoSwift
import os.log

/// Service that exports all data for a child as a sectioned CSV string.
@MainActor
final class ExportService {

    private let dittoManager: any DittoManaging
    private let logger = Logger(subsystem: "com.gentleguardian.app", category: "ExportService")

    init(dittoManager: any DittoManaging) {
        self.dittoManager = dittoManager
    }

    /// Queries all collections for the given child and returns a CSV string.
    func generateCSV(for child: Child, childId: String) async throws -> String {
        // Fetch all collections concurrently
        async let feedingResult = fetchEvents(
            from: AppConstants.Collections.feeding,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let diaperResult = fetchEvents(
            from: AppConstants.Collections.diaper,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let sleepResult = fetchEvents(
            from: AppConstants.Collections.sleep,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let activityResult = fetchEvents(
            from: AppConstants.Collections.activity,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let healthResult = fetchEvents(
            from: AppConstants.Collections.health,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let otherResult = fetchEvents(
            from: AppConstants.Collections.otherEvents,
            childId: childId,
            orderBy: "timestamp DESC"
        )
        async let vaccinationResult = fetchEvents(
            from: AppConstants.Collections.vaccinationRecords,
            childId: childId,
            orderBy: "dateAdministered DESC"
        )
        async let customItemResult = fetchEvents(
            from: AppConstants.Collections.customItems,
            childId: childId,
            orderBy: "name ASC"
        )

        let feedings = try await feedingResult.map { FeedingEvent(from: $0) }
        let diapers = try await diaperResult.map { DiaperEvent(from: $0) }
        let sleeps = try await sleepResult.map { SleepEvent(from: $0) }
        let activities = try await activityResult.map { ActivityEvent(from: $0) }
        let healths = try await healthResult.map { HealthEvent(from: $0) }
        let others = try await otherResult.map { OtherEvent(from: $0) }
        let vaccinations = try await vaccinationResult.map { VaccinationRecord(from: $0) }
        let customItems = try await customItemResult.map { CustomItem(from: $0) }

        let totalEvents = feedings.count + diapers.count + sleeps.count
            + activities.count + healths.count + others.count
            + vaccinations.count + customItems.count

        logger.info("Export: fetched \(totalEvents) total records for child \(childId)")

        return buildCSV(
            child: child,
            totalEvents: totalEvents,
            feedings: feedings,
            diapers: diapers,
            sleeps: sleeps,
            activities: activities,
            healths: healths,
            others: others,
            vaccinations: vaccinations,
            customItems: customItems
        )
    }

    // MARK: - Fetch

    private func fetchEvents(
        from collection: String,
        childId: String,
        orderBy: String
    ) async throws -> [[String: Any?]] {
        let query = QueryHelpers.selectForChild(from: collection, orderBy: orderBy)
        let result = try await dittoManager.execute(
            query: query,
            arguments: QueryHelpers.childArgs(childId)
        )
        return result.items.map { item in
            let doc = item.value
            item.dematerialize()
            return doc
        }
    }

    // MARK: - Build CSV

    private func buildCSV(
        child: Child,
        totalEvents: Int,
        feedings: [FeedingEvent],
        diapers: [DiaperEvent],
        sleeps: [SleepEvent],
        activities: [ActivityEvent],
        healths: [HealthEvent],
        others: [OtherEvent],
        vaccinations: [VaccinationRecord],
        customItems: [CustomItem]
    ) -> String {
        var csv = ""

        // Header metadata
        csv += "# GentleGuardian Data Export\n"
        csv += "# Child: \(child.firstName)\n"
        csv += "# Exported: \(DateService.displayDateTime(from: Date()))\n"
        csv += "# Total Records: \(totalEvents)\n"
        csv += "#\n"

        // Child Profile
        csv += "# Child Profile\n"
        csv += "First Name,Birthday,Sex,Prematurity Weeks,Prematurity Status,Sync Code,Day Start Hour,Day End Hour,Vaccination Region,Vaccination Country,Vaccination Tracking\n"
        csv += row([
            child.firstName,
            DateService.displayDate(from: child.birthday),
            child.sex.rawValue,
            optStr(child.prematurityWeeks),
            child.prematurityStatus?.displayName ?? "",
            child.syncCode,
            String(child.dayStartHour),
            String(child.dayEndHour),
            child.vaccinationRegion ?? "",
            child.vaccinationCountry ?? "",
            child.isVaccinationTrackingEnabled ? "Yes" : "No"
        ])
        csv += "#\n"

        // Feeding Events
        csv += "# Feeding Events (\(feedings.count))\n"
        csv += "Date,Time,Type,Bottle Qty,Bottle Unit,Formula,Breast Duration (min),Breast Side,Solid Type,Solid Qty,Solid Unit,Notes\n"
        for e in feedings {
            csv += row([
                DateService.dateString(from: e.timestamp),
                DateService.displayTime(from: e.timestamp),
                e.type.rawValue,
                optDouble(e.bottleQuantity),
                e.bottleQuantityUnit?.rawValue ?? "",
                e.formulaType ?? "",
                optInt(e.breastDurationMinutes),
                e.breastSide?.rawValue ?? "",
                e.solidType ?? "",
                optDouble(e.solidQuantity),
                e.solidQuantityUnit?.rawValue ?? "",
                e.notes
            ])
        }
        csv += "#\n"

        // Diaper Events
        csv += "# Diaper Events (\(diapers.count))\n"
        csv += "Date,Time,Type,Quantity,Color,Consistency,Notes\n"
        for e in diapers {
            csv += row([
                DateService.dateString(from: e.timestamp),
                DateService.displayTime(from: e.timestamp),
                e.type.rawValue,
                e.quantity.rawValue,
                e.color?.rawValue ?? "",
                e.consistency?.rawValue ?? "",
                e.notes
            ])
        }
        csv += "#\n"

        // Sleep Events
        csv += "# Sleep Events (\(sleeps.count))\n"
        csv += "Date,Start Time,End Time,Duration (min),Notes\n"
        for e in sleeps {
            csv += row([
                DateService.dateString(from: e.startTime),
                DateService.displayTime(from: e.startTime),
                DateService.displayTime(from: e.endTime),
                String(e.durationMinutes),
                e.notes
            ])
        }
        csv += "#\n"

        // Activity Events
        csv += "# Activity Events (\(activities.count))\n"
        csv += "Date,Time,Activity Type,Duration (min),Description\n"
        for e in activities {
            csv += row([
                DateService.dateString(from: e.timestamp),
                DateService.displayTime(from: e.timestamp),
                e.activityType.rawValue,
                optInt(e.durationMinutes),
                e.description
            ])
        }
        csv += "#\n"

        // Health Events
        csv += "# Health Events (\(healths.count))\n"
        csv += "Date,Time,Type,Medicine,Med Qty,Med Unit,Temperature,Temp Unit,Height,Height Unit,Weight,Weight Unit,Notes\n"
        for e in healths {
            csv += row([
                DateService.dateString(from: e.timestamp),
                DateService.displayTime(from: e.timestamp),
                e.type.rawValue,
                e.medicineName ?? "",
                optDouble(e.medicineQuantity),
                e.medicineQuantityUnit?.rawValue ?? "",
                optDouble(e.temperatureValue),
                e.temperatureUnit?.rawValue ?? "",
                optDouble(e.heightValue),
                e.heightUnit?.rawValue ?? "",
                optDouble(e.weightValue),
                e.weightUnit?.rawValue ?? "",
                e.notes
            ])
        }
        csv += "#\n"

        // Other Events
        csv += "# Other Events (\(others.count))\n"
        csv += "Date,Time,Name,Duration (min),Description\n"
        for e in others {
            csv += row([
                DateService.dateString(from: e.timestamp),
                DateService.displayTime(from: e.timestamp),
                e.name,
                optInt(e.durationMinutes),
                e.description
            ])
        }
        csv += "#\n"

        // Vaccination Records
        csv += "# Vaccination Records (\(vaccinations.count))\n"
        csv += "Date Administered,Vaccine Type,Dose Number,Custom Name,Custom Description,Notes\n"
        for r in vaccinations {
            csv += row([
                DateService.displayDate(from: r.dateAdministered),
                r.vaccineType,
                r.doseNumber > 0 ? String(r.doseNumber) : "",
                r.customVaccineName ?? "",
                r.customVaccineDescription ?? "",
                r.notes ?? ""
            ])
        }
        csv += "#\n"

        // Custom Items
        csv += "# Custom Items (\(customItems.count))\n"
        csv += "Category,Name,Default Qty,Default Unit\n"
        for item in customItems {
            csv += row([
                item.category.rawValue,
                item.name,
                optDouble(item.defaultQuantity),
                item.defaultQuantityUnit ?? ""
            ])
        }

        return csv
    }

    // MARK: - CSV Helpers

    /// Builds a single CSV row from an array of field values, with proper escaping.
    private func row(_ fields: [String]) -> String {
        fields.map { csvEscape($0) }.joined(separator: ",") + "\n"
    }

    /// Escapes a CSV field per RFC 4180: quotes fields containing commas, quotes, or newlines.
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func optDouble(_ value: Double?) -> String {
        guard let value else { return "" }
        // Drop trailing .0 for whole numbers
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }

    private func optInt(_ value: Int?) -> String {
        guard let value else { return "" }
        return String(value)
    }

    private func optStr(_ value: Int?) -> String {
        guard let value else { return "" }
        return String(value)
    }
}
