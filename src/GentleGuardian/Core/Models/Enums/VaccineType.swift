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
