import SwiftUI

/// Detail view for a single age group showing all doses with their statuses.
struct AgeGroupDetailView: View {

    let group: AgeGroup
    let vaccinationRepository: VaccinationRepository
    let vaccinationViewModel: VaccinationViewModel

    @Environment(\.colorScheme) private var colorScheme

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
                        .foregroundStyle(colors.error)
                } else if status == .pending {
                    Text("Not recorded \u{00B7} due now")
                        .font(.ggBodySmall)
                        .foregroundStyle(colors.tertiary)
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
                    .fill(colors.error)
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
                .strokeBorder(colors.error, lineWidth: 2)
                .overlay(Image(systemName: "exclamationmark").font(.caption2).foregroundStyle(colors.error))
        case .pending:
            Circle()
                .strokeBorder(colors.tertiary, lineWidth: 2)
                .overlay(Image(systemName: "ellipsis").font(.caption2).foregroundStyle(colors.tertiary))
        case .upcoming:
            Circle()
                .strokeBorder(colors.onSurface.opacity(0.3), lineWidth: 1.5)
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
