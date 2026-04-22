import SwiftUI

/// Sheet for batch-logging multiple vaccination doses — stub, implemented in Task 13.
struct LogBatchVaccinationSheet: View {
    let doses: [ScheduledDose]
    let vaccinationRepository: VaccinationRepository
    let child: Child?

    var body: some View {
        Text("Batch Log — Coming in Task 13")
    }
}
