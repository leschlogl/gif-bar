import SwiftUI
import XCTest
@testable import DesignSystem

@MainActor
final class EmptyStateViewSnapshotTests: XCTestCase {
    func testDefault() {
        // These text tokens are tuned for the app's dark popover background — render
        // over an approximation of it here rather than the test host's default white,
        // or the title text is essentially invisible.
        let view = ZStack {
            SwiftUI.Color.black
            DesignTokens.Color.popoverTint
            EmptyStateView(
                icon: "face.dashed",
                title: "No Results",
                subtitle: "Try a different search term."
            )
        }

        assertViewSnapshot(view, size: CGSize(width: DesignTokens.Layout.popoverSize.width, height: 220))
    }
}
