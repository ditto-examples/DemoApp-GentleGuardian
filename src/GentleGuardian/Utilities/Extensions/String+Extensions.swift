import Foundation

extension String {

    /// Trims whitespace and newlines from both ends of the string.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns nil if the string is empty after trimming, otherwise returns the trimmed string.
    var nilIfEmpty: String? {
        let trimmed = self.trimmed
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Returns true if this string contains only uppercase alphanumeric characters.
    var isUppercaseAlphanumeric: Bool {
        let allowed = CharacterSet.uppercaseLetters.union(.decimalDigits)
        return unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
