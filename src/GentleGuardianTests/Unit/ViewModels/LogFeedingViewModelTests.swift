import Testing
import Foundation
@testable import GentleGuardian

/// Tests for LogFeedingViewModel covering validation and save for all feeding subtypes.
@MainActor
struct LogFeedingViewModelTests {

    // MARK: - Helpers

    private func makeSUT(type: FeedingType = .bottle) -> (LogFeedingViewModel, MockFeedingRepository, MockCustomItemRepository) {
        let feedingRepo = MockFeedingRepository()
        let customItemRepo = MockCustomItemRepository()
        let viewModel = LogFeedingViewModel(
            childId: "child-1",
            feedingRepository: feedingRepo,
            customItemRepository: customItemRepo,
            initialType: type
        )
        return (viewModel, feedingRepo, customItemRepo)
    }

    // MARK: - Bottle Validation

    @Test("Bottle form requires quantity")
    func bottleFormRequiresQuantity() {
        let (viewModel, _, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = ""

        #expect(!viewModel.isFormValid)
    }

    @Test("Bottle form valid with numeric quantity")
    func bottleFormValidWithQuantity() {
        let (viewModel, _, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = "4.5"

        #expect(viewModel.isFormValid)
        #expect(viewModel.bottleQuantityValue == 4.5)
    }

    @Test("Bottle form invalid with non-numeric quantity")
    func bottleFormInvalidWithNonNumericQuantity() {
        let (viewModel, _, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = "abc"

        #expect(!viewModel.isFormValid)
        #expect(viewModel.bottleQuantityValue == nil)
    }

    // MARK: - Breast Validation

    @Test("Breast form requires duration")
    func breastFormRequiresDuration() {
        let (viewModel, _, _) = makeSUT(type: .breast)
        viewModel.breastDuration = ""

        #expect(!viewModel.isFormValid)
    }

    @Test("Breast form valid with numeric duration")
    func breastFormValidWithDuration() {
        let (viewModel, _, _) = makeSUT(type: .breast)
        viewModel.breastDuration = "15"

        #expect(viewModel.isFormValid)
        #expect(viewModel.breastDurationValue == 15)
    }

    // MARK: - Solid Validation

    @Test("Solid form requires food type")
    func solidFormRequiresFoodType() {
        let (viewModel, _, _) = makeSUT(type: .solid)
        viewModel.solidType = ""

        #expect(!viewModel.isFormValid)
    }

    @Test("Solid form valid with food type only")
    func solidFormValidWithFoodTypeOnly() {
        let (viewModel, _, _) = makeSUT(type: .solid)
        viewModel.solidType = "Sweet potato puree"

        #expect(viewModel.isFormValid)
    }

    @Test("Solid form valid with food type and quantity")
    func solidFormValidWithFoodTypeAndQuantity() {
        let (viewModel, _, _) = makeSUT(type: .solid)
        viewModel.solidType = "Banana"
        viewModel.solidQuantity = "2"
        viewModel.solidUnit = .tbsp

        #expect(viewModel.isFormValid)
        #expect(viewModel.solidQuantityValue == 2.0)
    }

    // MARK: - Save Tests

    @Test("Save bottle creates correct event")
    func saveBottleCreatesCorrectEvent() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = "6"
        viewModel.bottleUnit = .oz
        viewModel.formulaType = "Similac"
        viewModel.notes = "Fed well"

        await viewModel.save()

        #expect(viewModel.didSave)
        #expect(feedingRepo.insertedEvents.count == 1)

        let event = feedingRepo.insertedEvents.first!
        #expect(event.childId == "child-1")
        #expect(event.type == .bottle)
        #expect(event.bottleQuantity == 6.0)
        #expect(event.bottleQuantityUnit == .oz)
        #expect(event.formulaType == "Similac")
        #expect(event.notes == "Fed well")
        // Breast fields should be nil
        #expect(event.breastDurationMinutes == nil)
        #expect(event.breastSide == nil)
        // Solid fields should be nil
        #expect(event.solidType == nil)
    }

    @Test("Save breast creates correct event")
    func saveBreastCreatesCorrectEvent() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .breast)
        viewModel.breastDuration = "20"
        viewModel.breastSide = .both

        await viewModel.save()

        #expect(viewModel.didSave)
        let event = feedingRepo.insertedEvents.first!
        #expect(event.type == .breast)
        #expect(event.breastDurationMinutes == 20)
        #expect(event.breastSide == .both)
        // Bottle fields should be nil
        #expect(event.bottleQuantity == nil)
    }

    @Test("Save solid creates correct event")
    func saveSolidCreatesCorrectEvent() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .solid)
        viewModel.solidType = "Avocado"
        viewModel.solidQuantity = "3"
        viewModel.solidUnit = .tbsp

        await viewModel.save()

        #expect(viewModel.didSave)
        let event = feedingRepo.insertedEvents.first!
        #expect(event.type == .solid)
        #expect(event.solidType == "Avocado")
        #expect(event.solidQuantity == 3.0)
        #expect(event.solidQuantityUnit == .tbsp)
    }

    @Test("Save failure shows error message")
    func saveFailureShowsError() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = "4"
        feedingRepo.shouldThrow = true

        await viewModel.save()

        #expect(!viewModel.didSave)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Invalid form does not save")
    func invalidFormDoesNotSave() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = ""

        await viewModel.save()

        #expect(feedingRepo.insertedEvents.isEmpty)
        #expect(!viewModel.didSave)
    }

    // MARK: - Custom Item Tests

    @Test("Add new formula creates custom item")
    func addNewFormulaCreatesCustomItem() async {
        let (viewModel, _, customItemRepo) = makeSUT(type: .bottle)
        viewModel.newFormulaName = "Similac Pro"

        await viewModel.addNewFormula()

        #expect(customItemRepo.insertedItems.count == 1)
        #expect(customItemRepo.insertedItems.first?.category == .formula)
        #expect(customItemRepo.insertedItems.first?.name == "Similac Pro")
        #expect(viewModel.formulaType == "Similac Pro")
        #expect(viewModel.newFormulaName.isEmpty)
    }

    @Test("Add new food creates custom item")
    func addNewFoodCreatesCustomItem() async {
        let (viewModel, _, customItemRepo) = makeSUT(type: .solid)
        viewModel.newFoodName = "Sweet Potato"

        await viewModel.addNewFood()

        #expect(customItemRepo.insertedItems.count == 1)
        #expect(customItemRepo.insertedItems.first?.category == .solidFood)
        #expect(customItemRepo.insertedItems.first?.name == "Sweet Potato")
        #expect(viewModel.solidType == "Sweet Potato")
    }

    @Test("Bottle save without formula leaves formulaType nil")
    func bottleSaveWithoutFormula() async {
        let (viewModel, feedingRepo, _) = makeSUT(type: .bottle)
        viewModel.bottleQuantity = "4"
        viewModel.formulaType = ""

        await viewModel.save()

        let event = feedingRepo.insertedEvents.first!
        #expect(event.formulaType == nil)
    }
}
