import XCTest

/// Drives the real app end-to-end against the live Giphy API (a real `GIPHY_API_KEY`
/// must be set in `Config/Secrets.xcconfig`) — these launch and click through the actual
/// menu bar UI, so they need to run on a machine with a display and can't be verified
/// from a headless session. See ROADMAP.md milestone 9.2.
final class GIFBarUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Opens the menu bar popover by clicking the app's status item. `MenuBarExtra`'s
    /// status item is exposed as a status item of the app's own process (not a separate
    /// System UI Server process), so it's reachable via `app.statusItems` directly.
    @discardableResult
    private func openPopover(_ app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5), "menu bar status item never appeared")
        statusItem.click()
        return statusItem
    }

    private func waitForAnyGifCard(_ app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let card = app.buttons.matching(identifier: "gifCard").element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "no GIF card appeared in time")
        return card
    }

    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testTrendingGifsLoadOnLaunch() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)

        waitForAnyGifCard(app)
    }

    func testSearchFiltersResults() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        waitForAnyGifCard(app)

        let searchField = app.textFields["searchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.click()
        searchField.typeText("cat")

        // Re-querying (rather than reusing the pre-search card) confirms the grid
        // actually reloaded with new content, not just that old cards are still on screen.
        waitForAnyGifCard(app)

        let clearButton = app.buttons["clearSearchButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.click()
        XCTAssertEqual(searchField.value as? String, "", "clear button should empty the search field")
    }

    func testInfiniteScrollLoadsMoreResults() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        waitForAnyGifCard(app)

        let initialCount = app.buttons.matching(identifier: "gifCard").count

        let grid = app.scrollViews.firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        for _ in 0..<5 {
            grid.scroll(byDeltaX: 0, deltaY: -600)
        }

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                app.buttons.matching(identifier: "gifCard").count > initialCount
            },
            object: nil
        )
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 10), .completed, "pagination never appended more cards")
    }

    func testFavoriteThenUnfavoriteAGif() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        let card = waitForAnyGifCard(app)

        let favoriteButton = app.buttons.matching(identifier: "favoriteButton").element(boundBy: 0)
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.click()
        XCTAssertTrue(app.staticTexts["Added to Favorites"].waitForExistence(timeout: 5))

        let favoritesToggle = app.buttons["favoritesToggleButton"]
        XCTAssertTrue(favoritesToggle.waitForExistence(timeout: 5))
        favoritesToggle.click()
        waitForAnyGifCard(app)

        favoriteButton.click()
        XCTAssertTrue(app.staticTexts["Removed from Favorites"].waitForExistence(timeout: 5))

        _ = card
    }

    func testCopyURLShowsToast() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        let card = waitForAnyGifCard(app)
        card.click()

        let copyURLButton = app.buttons["Copy URL"]
        XCTAssertTrue(copyURLButton.waitForExistence(timeout: 5))
        copyURLButton.click()
        XCTAssertTrue(app.staticTexts["Link Copied"].waitForExistence(timeout: 5))
    }

    func testCopyGifShowsToast() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        let card = waitForAnyGifCard(app)
        card.click()

        let copyGifButton = app.buttons["Copy GIF"]
        XCTAssertTrue(copyGifButton.waitForExistence(timeout: 5))
        copyGifButton.click()
        XCTAssertTrue(app.staticTexts["GIF Copied"].waitForExistence(timeout: 10), "binary copy downloads real bytes, so allow more time than the URL copy")
    }

    func testFavoritePersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        openPopover(app)
        waitForAnyGifCard(app)

        let favoriteButton = app.buttons.matching(identifier: "favoriteButton").element(boundBy: 0)
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.click()
        XCTAssertTrue(app.staticTexts["Added to Favorites"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        openPopover(app)

        let favoritesToggle = app.buttons["favoritesToggleButton"]
        XCTAssertTrue(favoritesToggle.waitForExistence(timeout: 5))
        favoritesToggle.click()

        waitForAnyGifCard(app)
    }
}
