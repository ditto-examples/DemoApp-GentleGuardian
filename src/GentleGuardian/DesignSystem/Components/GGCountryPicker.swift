import SwiftUI

/// Reusable country picker that lists every ISO 3166-1 country with a flag
/// emoji and the locale-localized name.
///
/// The system-locale country (if known) is pinned to the top of the list as a
/// quick-pick suggestion.
struct GGCountryPicker: View {

    /// Two-letter ISO country code currently selected.
    @Binding var selectedCode: String

    /// Optional title rendered above the picker.
    var title: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: GGSpacing.sm) {
            if let title {
                Text(title)
                    .font(.ggLabelMedium)
                    .foregroundStyle(colors.onSurface.opacity(0.6))
            }

            Picker(title ?? "Country", selection: $selectedCode) {
                if let system = CountryCatalog.systemDefault {
                    Text("\(system.flagEmoji) \(system.name)")
                        .tag(system.code)
                    Divider().tag("__divider__")
                }
                ForEach(CountryCatalog.all) { country in
                    Text("\(country.flagEmoji) \(country.name)")
                        .tag(country.code)
                }
            }
            .wheelPickerStyle()
            .frame(height: 150)
            .tint(colors.primary)
        }
    }

    private var colors: GGAdaptiveColors {
        GGAdaptiveColors(colorScheme: colorScheme)
    }
}
