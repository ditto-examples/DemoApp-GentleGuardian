import Foundation

/// A single dose in a country's recommended vaccination schedule.
struct ScheduledDose: Codable, Sendable, Equatable, Identifiable {
    let vaccineType: String
    let doseNumber: Int
    let recommendedAgeMinMonths: Double
    let recommendedAgeMaxMonths: Double
    let ageGroupLabel: String
    let displayName: String
    let abbreviation: String

    var id: String { "\(vaccineType)-\(doseNumber)" }
}

/// A country's complete vaccination schedule.
struct CountrySchedule: Codable, Sendable {
    let name: String
    let source: String
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
