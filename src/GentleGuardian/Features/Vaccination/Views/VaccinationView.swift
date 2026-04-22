import SwiftUI

/// Main vaccination tab showing progress summary and age-grouped checklist.
struct VaccinationView: View {

    @Environment(ActiveChildState.self) private var activeChildState
    @Environment(\.colorScheme) private var colorScheme

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
            statPill(title: "Overdue", value: "\(progress.overdueCount)", valueColor: colors.error)
            statPill(title: "Pending", value: "\(progress.pendingCount)", valueColor: colors.tertiary)
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
                    .stroke(colors.error.opacity(0.4), lineWidth: 1)
                    .overlay(
                        Rectangle()
                            .fill(colors.error)
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
                .fill(colors.error)
                .overlay(Image(systemName: "exclamationmark").font(.caption2).foregroundStyle(.white))
        case .pending:
            Circle()
                .fill(colors.tertiary)
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
        case .overdue: colors.error
        case .pending: colors.tertiary
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
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
