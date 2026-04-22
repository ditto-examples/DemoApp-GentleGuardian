import SwiftUI

/// Sheet for logging a single scheduled vaccination dose — stub, implemented in Task 13.
struct LogVaccinationSheet: View {
    let dose: ScheduledDose
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    var body: some View {
        Text("Log Vaccination — Coming in Task 13")
    }
}
