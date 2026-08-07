import DesignSystem
import SwiftUI
import XCTest
@testable import Views

@MainActor
final class LoadingSkeletonGridSnapshotTests: XCTestCase {
    func testDefault() {
        let view = ZStack {
            SwiftUI.Color.black
            DesignTokens.Color.popoverTint
            LoadingSkeletonGrid()
                .padding(DesignTokens.Spacing.contentPaddingSides)
        }

        assertViewSnapshot(
            view,
            size: CGSize(width: DesignTokens.Layout.popoverSize.width, height: 460)
        )
    }
}
