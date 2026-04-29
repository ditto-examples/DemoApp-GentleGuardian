import Foundation

/// Lightweight value type representing an ISO 3166-1 alpha-2 country
/// with a localized display name and flag emoji for picker UI.
struct Country: Identifiable, Hashable, Sendable {

    /// ISO 3166-1 alpha-2 code (e.g. "US", "GB", "JP").
    let code: String

    /// Localized display name in the current locale.
    let name: String

    /// Unicode flag emoji derived from the country code.
    let flagEmoji: String

    var id: String { code }

    init(code: String, name: String) {
        self.code = code
        self.name = name
        self.flagEmoji = Self.flagEmoji(for: code)
    }

    /// Converts a 2-letter country code into its Unicode flag emoji.
    /// Returns an empty string if the code is invalid.
    static func flagEmoji(for code: String) -> String {
        let upper = code.uppercased()
        guard upper.count == 2 else { return "" }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in upper.unicodeScalars {
            guard let s = Unicode.Scalar(base + scalar.value) else { continue }
            emoji.unicodeScalars.append(s)
        }
        return emoji
    }
}

/// Curated catalog of all ISO 3166-1 countries known to the system locale.
///
/// The list is built once from `Locale.Region.isoRegions` and sorted by the
/// localized name. Pinning the system locale's country first is handled at
/// the picker level, not in the catalog itself.
enum CountryCatalog {

    /// All countries known to the current system locale, sorted alphabetically by localized name.
    static let all: [Country] = {
        let locale = Locale.current
        let regions = Locale.Region.isoRegions.filter { $0.subRegions.isEmpty }
        let countries: [Country] = regions.compactMap { region in
            let code = region.identifier
            // ISO regions include some non-country codes; filter to alpha-2 only.
            guard code.count == 2,
                  let name = locale.localizedString(forRegionCode: code),
                  !name.isEmpty
            else { return nil }
            return Country(code: code, name: name)
        }
        return countries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    /// Returns the country matching the system locale's region, or `nil` if it
    /// can't be determined.
    static var systemDefault: Country? {
        guard let regionCode = Locale.current.region?.identifier else { return nil }
        return all.first { $0.code == regionCode }
    }

    /// Looks up a country by ISO alpha-2 code.
    static func country(for code: String) -> Country? {
        all.first { $0.code == code.uppercased() }
    }
}
