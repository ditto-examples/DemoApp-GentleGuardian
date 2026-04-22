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
                            .wheelPickerStyle()
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
