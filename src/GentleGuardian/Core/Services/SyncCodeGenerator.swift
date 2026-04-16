import Foundation
import Security

/// Generates cryptographically secure sync codes for child device pairing.
enum SyncCodeGenerator {

    /// Generates a random alphanumeric sync code.
    ///
    /// Uses `SecRandomCopyBytes` for cryptographic randomness. The code is
    /// uppercase alphanumeric with ambiguous characters (0, O, 1, I) excluded
    /// as defined in `AppConstants.syncCodeCharacters`.
    ///
    /// - Parameter length: The number of characters in the code. Defaults to `AppConstants.syncCodeLength`.
    /// - Returns: A random sync code string.
    static func generate(length: Int = AppConstants.syncCodeLength) -> String {
        let characters = Array(AppConstants.syncCodeCharacters)
        let count = characters.count

        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

        guard status == errSecSuccess else {
            // Fallback to SystemRandomNumberGenerator if SecRandom fails
            return fallbackGenerate(length: length, characters: characters)
        }

        let code = randomBytes.map { byte in
            characters[Int(byte) % count]
        }

        return String(code)
    }

    /// Fallback generation using Swift's built-in random number generator.
    private static func fallbackGenerate(length: Int, characters: [Character]) -> String {
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(characters.randomElement()!)
        }
        return result
    }

    /// Validates that a sync code matches the expected format.
    ///
    /// - Parameter code: The code to validate.
    /// - Returns: `true` if the code is the correct length and contains only allowed characters.
    static func isValid(_ code: String) -> Bool {
        guard code.count == AppConstants.syncCodeLength else { return false }
        let allowedCharacters = CharacterSet(charactersIn: AppConstants.syncCodeCharacters)
        return code.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}
