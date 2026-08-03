import XCTest
@testable import DesignSystem

final class DesignTokensTests: XCTestCase {
    func testLayoutConstants() {
        XCTAssertEqual(DesignTokens.Layout.popoverSize.width, 380)
        XCTAssertEqual(DesignTokens.Layout.popoverSize.height, 580)
        XCTAssertEqual(DesignTokens.Layout.toolbarHeight, 52)
        XCTAssertEqual(DesignTokens.Layout.gridColumns, 2)
    }

    func testRadiusConstants() {
        XCTAssertEqual(DesignTokens.Radius.popover, 20)
        XCTAssertEqual(DesignTokens.Radius.card, 16)
        XCTAssertEqual(DesignTokens.Radius.searchField, 9)
        XCTAssertEqual(DesignTokens.Radius.pill, 15)
    }

    func testSpacingConstants() {
        XCTAssertEqual(DesignTokens.Spacing.gridGutter, 12)
        XCTAssertEqual(DesignTokens.Spacing.cardMarginBottom, 12)
        XCTAssertEqual(DesignTokens.Spacing.tabGap, 16)
    }
}
