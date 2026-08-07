import SwiftUI
import XCTest
@testable import DesignSystem

@MainActor
final class ErrorStateViewSnapshotTests: XCTestCase {
    func testDefault() {
        // Same rationale as EmptyStateViewSnapshotTests: render over an approximation
        // of the app's dark popover background so the (near-white) title text is visible.
        let view = ZStack {
            SwiftUI.Color.black
            DesignTokens.Color.popoverTint
            ErrorStateView(retryAction: {})
        }

        assertViewSnapshot(view, size: CGSize(width: DesignTokens.Layout.popoverSize.width, height: 260))
    }
}
