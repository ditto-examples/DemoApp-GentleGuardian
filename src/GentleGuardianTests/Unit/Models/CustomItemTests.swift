import Testing
import Foundation
@testable import GentleGuardian

/// Tests for the CustomItem model's initialization and serialization.
@Suite("CustomItem Model Tests")
struct CustomItemTests {

    @Test("CustomItem initializes correctly")
    func customItemInit() {
        let item = CustomItem(
            childId: "child-1",
            category: .formula,
            name: "Similac",
            defaultQuantity: 4.0,
            defaultQuantityUnit: "oz"
        )

        #expect(item.category == .formula)
        #expect(item.name == "Similac")
        #expect(item.defaultQuantity == 4.0)
        #expect(item.defaultQuantityUnit == "oz")
        #expect(item.isArchived == false)
    }

    @Test("CustomItem round-trips through Ditto document")
    func customItemDittoRoundTrip() {
        let original = CustomItem(
            id: "custom-1",
            childId: "child-1",
            category: .medicine,
            name: "Tylenol",
            defaultQuantity: 2.5,
            defaultQuantityUnit: "ml"
        )

        let doc = original.toDittoDocument()
        let restored = CustomItem(from: doc)

        #expect(restored.id == "custom-1")
        #expect(restored.childId == "child-1")
        #expect(restored.category == .medicine)
        #expect(restored.name == "Tylenol")
        #expect(restored.defaultQuantity == 2.5)
        #expect(restored.defaultQuantityUnit == "ml")
        #expect(restored.isArchived == false)
    }

    @Test("CustomItem from incomplete document")
    func customItemFromIncomplete() {
        let doc: [String: Any?] = [
            "_id": "item-1",
            "name": "Banana"
        ]

        let item = CustomItem(from: doc)
        #expect(item.id == "item-1")
        #expect(item.name == "Banana")
        #expect(item.category == .formula) // default
        #expect(item.defaultQuantity == nil)
    }
}
