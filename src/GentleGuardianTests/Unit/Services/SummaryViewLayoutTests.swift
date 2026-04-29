import Testing
import SwiftUI
@testable import GentleGuardian

#if os(iOS)
import UIKit
typealias HostController = UIHostingController<AnyView>
#elseif os(macOS)
import AppKit
typealias HostController = NSHostingController<AnyView>
#endif

/// Render-smoke tests for the Summary tab's stand-alone list views.
///
/// These do not assert on layout — they instantiate the view inside a host
/// controller, which forces SwiftUI to evaluate `body` and apply view
/// modifiers. If a recent change introduces a compile-time platform branch
/// that fails to compile, or a runtime crash inside `body`, these catch it.
@Suite("Summary Layout Render Smoke")
@MainActor
struct SummaryViewLayoutTests {

    @Test("FoodRankingList renders empty state for each filter")
    func foodRankingEmptyForEachFilter() {
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: [])
            _ = renderHost(view)
        }
    }

    @Test("FoodRankingList renders populated state for each filter")
    func foodRankingPopulatedForEachFilter() {
        let summaries: [FoodReactionSummary] = [
            FoodReactionSummary(
                foodName: "Avocado",
                totalCount: 3,
                happyCount: 2,
                neutralCount: 1,
                frownCount: 0
            ),
            FoodReactionSummary(
                foodName: "Broccoli",
                totalCount: 2,
                happyCount: 0,
                neutralCount: 0,
                frownCount: 2
            )
        ]
        for filter in FoodRankingFilter.allCases {
            let binding = Binding<FoodRankingFilter>.constant(filter)
            let view = FoodRankingList(filter: binding, summaries: summaries)
            _ = renderHost(view)
        }
    }

    // MARK: - Host helper

    private func renderHost<V: View>(_ view: V) -> HostController {
        let host = HostController(rootView: AnyView(view))
        #if os(iOS)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
        #elseif os(macOS)
        host.view.frame = NSRect(x: 0, y: 0, width: 600, height: 800)
        host.view.layoutSubtreeIfNeeded()
        #endif
        return host
    }
}
