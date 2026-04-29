import Foundation

/// Seeds the `customItems` collection with a snapshot of the FDA-published list
/// of US-marketed infant formulas. The snapshot is hardcoded so the app remains
/// fully offline-first; it is only seeded for children whose `country == "US"`.
///
/// Source: https://www.fda.gov/food/infant-formula-homepage/infant-formulas-marketed-us
enum FormulaSeed {

    /// Snapshot of US-marketed infant formula brand+product names known to the FDA.
    ///
    /// Names are kept human-friendly — caregivers will see and tap these in the
    /// picker. Where multiple stages exist (e.g. Stage 1, Stage 2), each is
    /// listed as its own entry so the daily summary can disambiguate.
    static let usFormulas: [String] = [
        // Abbott / Similac
        "Similac 360 Total Care",
        "Similac 360 Total Care Sensitive",
        "Similac Pro-Advance",
        "Similac Pro-Sensitive",
        "Similac Pro-Total Comfort",
        "Similac Sensitive",
        "Similac Total Comfort",
        "Similac Soy Isomil",
        "Similac for Spit-Up",
        "Similac NeoSure",
        "Similac Alimentum",
        "Similac Organic with A2 Milk",
        "Similac Special Care",
        "Similac PM 60/40",
        "Similac Human Milk Fortifier",
        "Similac Expert Care Alimentum",

        // Mead Johnson / Enfamil
        "Enfamil NeuroPro Infant",
        "Enfamil NeuroPro Sensitive",
        "Enfamil NeuroPro Gentlease",
        "Enfamil NeuroPro EnfaCare",
        "Enfamil Enspire",
        "Enfamil Enspire Optimum",
        "Enfamil Enspire Gentlease",
        "Enfamil Reguline",
        "Enfamil A.R.",
        "Enfamil ProSobee",
        "Enfamil Nutramigen",
        "Enfamil Nutramigen Hypoallergenic",
        "Enfamil PurAmino",
        "Enfamil Premium Infant",
        "Enfamil Premium Gentlease",
        "Enfamil EnfaCare",
        "Enfamil Human Milk Fortifier",

        // Nestlé / Gerber
        "Gerber Good Start GentlePro",
        "Gerber Good Start SoothePro",
        "Gerber Good Start SoyPro",
        "Gerber Good Start Extensive HA",
        "Gerber Good Start Premature",

        // Reckitt / Else / Bobbie / others
        "Bobbie Organic Infant Formula",
        "Bobbie Organic Gentle Infant Formula",
        "ByHeart Whole Nutrition Infant Formula",
        "Kendamil Organic Infant Formula",
        "Kendamil Classic Infant Formula",
        "Earth's Best Organic Infant Formula",
        "Earth's Best Organic Sensitivity Infant Formula",
        "Earth's Best Organic Soy Infant Formula",
        "Happy Baby Organic Infant Formula",
        "Happy Baby Organic Sensitive Infant Formula",
        "Parent's Choice Premium Infant",
        "Parent's Choice Gentle Infant",
        "Parent's Choice Sensitivity Infant",
        "Parent's Choice Advantage Premium",
        "Parent's Choice Soy Infant",
        "Up & Up Advantage Premium Infant",
        "Up & Up Gentle Infant",
        "Up & Up Sensitivity Infant",
        "Up & Up Soy Infant",
        "Member's Mark Infant Formula",
        "Berkley Jensen Infant Formula",

        // Specialty / metabolic / preterm
        "Neocate Infant",
        "Neocate Syneo Infant",
        "Alfamino Infant",
        "EleCare Infant",
        "PurAmino Junior",
        "Pregestimil",
        "Similac Special Care 24",
        "Enfamil Premature 24"
    ]

    /// Seeds US formulas into the `customItems` collection for the given child,
    /// but only if no formulas exist yet (idempotent).
    ///
    /// - Parameters:
    ///   - childId: The child to seed for.
    ///   - repository: The custom item repository to insert through.
    ///   - country: ISO 3166-1 alpha-2 code; seed only fires when this is "US".
    static func seedIfNeeded(
        childId: String,
        repository: CustomItemRepository,
        country: String?
    ) async {
        guard let country, country.uppercased() == "US" else { return }
        do {
            try await repository.bulkInsertIfEmpty(
                names: usFormulas,
                childId: childId,
                category: .formula,
                isSeeded: true
            )
        } catch {
            // Seeding is a best-effort enhancement — never block registration.
            // Caregivers can still add formulas manually via the picker's Manage screen.
        }
    }
}
