import Testing
import Foundation
@testable import GentleGuardian

/// Tests for SyncCodeGenerator.
@Suite("SyncCodeGenerator Tests")
struct SyncCodeGeneratorTests {

    @Test("Generated code has correct length")
    func codeLength() {
        let code = SyncCodeGenerator.generate()
        #expect(code.count == AppConstants.syncCodeLength)
    }

    @Test("Generated code contains only allowed characters")
    func codeCharacterSet() {
        let allowedChars = Set(AppConstants.syncCodeCharacters)
        for _ in 0..<100 {
            let code = SyncCodeGenerator.generate()
            for char in code {
                #expect(allowedChars.contains(char), "Unexpected character: \(char)")
            }
        }
    }

    @Test("Generated codes are unique")
    func codeUniqueness() {
        var codes = Set<String>()
        for _ in 0..<100 {
            codes.insert(SyncCodeGenerator.generate())
        }
        // With 29^6 (~594 million) possible codes, 100 should all be unique
        #expect(codes.count == 100)
    }

    @Test("Custom length codes work")
    func customLength() {
        let code = SyncCodeGenerator.generate(length: 10)
        #expect(code.count == 10)
    }

    @Test("isValid accepts valid codes")
    func validCodes() {
        #expect(SyncCodeGenerator.isValid("ABC234"))
        #expect(SyncCodeGenerator.isValid("ZZZZZ9"))
    }

    @Test("isValid rejects invalid codes")
    func invalidCodes() {
        // Too short
        #expect(!SyncCodeGenerator.isValid("ABC"))
        // Too long
        #expect(!SyncCodeGenerator.isValid("ABCDEFGH"))
        // Contains lowercase
        #expect(!SyncCodeGenerator.isValid("abcdef"))
        // Contains excluded characters (0, 1, I, O)
        #expect(!SyncCodeGenerator.isValid("ABCDE0"))
        #expect(!SyncCodeGenerator.isValid("ABCDE1"))
        #expect(!SyncCodeGenerator.isValid("ABCDEI"))
        #expect(!SyncCodeGenerator.isValid("ABCDEO"))
        // Empty
        #expect(!SyncCodeGenerator.isValid(""))
    }
}
