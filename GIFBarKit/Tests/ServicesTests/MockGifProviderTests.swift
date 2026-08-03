import XCTest
@testable import Services

final class MockGifProviderTests: XCTestCase {
    private func makeProvider() -> MockGifProvider {
        MockGifProvider(latency: .zero)
    }

    func testTrendingFirstPage() async throws {
        let page = try await makeProvider().trending(offset: 0, limit: 8)
        XCTAssertEqual(page.gifs.count, 8)
        XCTAssertEqual(page.gifs.first?.id, "1")
        XCTAssertTrue(page.hasMore)
    }

    func testTrendingLastPageHasNoMore() async throws {
        let page = try await makeProvider().trending(offset: 16, limit: 8)
        XCTAssertEqual(page.gifs.count, 2)
        XCTAssertFalse(page.hasMore)
    }

    func testTrendingOffsetPastEndReturnsEmpty() async throws {
        let page = try await makeProvider().trending(offset: 100, limit: 8)
        XCTAssertEqual(page.gifs, [])
        XCTAssertFalse(page.hasMore)
    }

    func testSearchIsCaseInsensitiveAndPaginated() async throws {
        let page = try await makeProvider().search(query: "clap", offset: 0, limit: 1)
        XCTAssertEqual(page.gifs.count, 1)
        XCTAssertTrue(page.hasMore, "expected more than one match for 'clap' (Clapping Hands, Slow Clap, Golf Clap)")
    }

    func testSearchEmptyQueryMatchesEverything() async throws {
        let page = try await makeProvider().search(query: "", offset: 0, limit: 100)
        XCTAssertEqual(page.gifs.count, 18)
    }

    func testFetchReturnsInRequestedOrderAndDropsUnknownIDs() async throws {
        let gifs = try await makeProvider().fetch(ids: ["5", "missing", "1"])
        XCTAssertEqual(gifs.map(\.id), ["5", "1"])
    }
}
