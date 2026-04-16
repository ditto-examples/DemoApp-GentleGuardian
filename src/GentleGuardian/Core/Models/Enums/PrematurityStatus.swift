import Foundation

/// Classification of prematurity based on gestational age at birth.
enum PrematurityStatus: String, Codable, CaseIterable, Sendable {
    case extremelyPreterm = "extremelyPreterm"
    case veryPreterm = "veryPreterm"
    case moderatePreterm = "moderatePreterm"
    case latePreterm = "latePreterm"
    case earlyTerm = "earlyTerm"

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .extremelyPreterm: "Extremely Preterm (<28 weeks)"
        case .veryPreterm: "Very Preterm (28-32 weeks)"
        case .moderatePreterm: "Moderate Preterm (32-34 weeks)"
        case .latePreterm: "Late Preterm (34-37 weeks)"
        case .earlyTerm: "Early Term (37-39 weeks)"
        }
    }

    /// Gestational weeks range for this status.
    var weeksRange: ClosedRange<Int> {
        switch self {
        case .extremelyPreterm: 22...27
        case .veryPreterm: 28...31
        case .moderatePreterm: 32...33
        case .latePreterm: 34...36
        case .earlyTerm: 37...38
        }
    }
}
