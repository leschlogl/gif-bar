import XCTest
@testable import ViewModels
import Models
import Services

private final class SpyGifProviding: GifProviding, @unchecked Sendable {
    private let wrapped: GifProviding
    private(set) var trendingCallCount = 0
    private(set) var searchCallCount = 0
    private(set) var lastSearchQuery: String?

    init(wrapping: GifProviding) {
        self.wrapped = wrapping
    }

    func trending(offset: Int, limit: Int) async throws -> GifPage {
        trendingCallCount += 1
        return try await wrapped.trending(offset: offset, limit: limit)
    }

    func search(query: String, offset: Int, limit: Int) async throws -> GifPage {
        searchCallCount += 1
        lastSearchQuery = query
        return try await wrapped.search(query: query, offset: offset, limit: limit)
    }

    func fetch(ids: [String]) async throws -> [Gif] {
        try await wrapped.fetch(ids: ids)
    }
}

private final class FakeFavoritesManaging: FavoritesManaging, @unchecked Sendable {
    private(set) var savedIDs: [String] = []
    var initialIDs: [String] = []

    func loadFavoriteIDs() async -> [String] { initialIDs }

    func setFavoriteIDs(_ ids: [String]) async {
        savedIDs = ids
        initialIDs = ids
    }
}

private final class FakeClipboardCopying: ClipboardCopying, @unchecked Sendable {
    private(set) var copiedURLIDs: [String] = []
    private(set) var copiedBinaryIDs: [String] = []

    func copyURL(gifID: String) async throws {
        copiedURLIDs.append(gifID)
    }

    func copyBinary(gifID: String) async throws {
        copiedBinaryIDs.append(gifID)
    }
}

@MainActor
final class GifBarViewModelTests: XCTestCase {
    private func makeViewModel(
        provider: GifProviding = MockGifProvider(latency: .zero),
        clipboard: ClipboardCopying = FakeClipboardCopying(),
        favorites: FakeFavoritesManaging = FakeFavoritesManaging()
    ) -> GifBarViewModel {
        GifBarViewModel(provider: provider, clipboard: clipboard, favorites: favorites)
    }

    private func waitForDebounce() async throws {
        try await Task.sleep(for: .milliseconds(350))
    }

    private func waitForBackgroundTask() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    func testInitialLoadPopulatesTrending() async {
        let viewModel = makeViewModel()
        await viewModel.onAppear()

        XCTAssertEqual(viewModel.gifs.count, 8)
        XCTAssertEqual(viewModel.gifs.first?.id, "1")
        XCTAssertTrue(viewModel.hasMore)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testTabSwitchResetsSelection() async {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        viewModel.selectedGifID = "1"

        viewModel.selectTab(.favorites)
        try? await waitForBackgroundTask()

        XCTAssertNil(viewModel.selectedGifID)
    }

    func testFavoritesEmptyFlag() async {
        let viewModel = makeViewModel()
        await viewModel.onAppear()

        viewModel.selectTab(.favorites)
        try? await waitForBackgroundTask()

        XCTAssertTrue(viewModel.isFavoritesEmpty)
        XCTAssertTrue(viewModel.gifs.isEmpty)
    }

    func testSearchEmptyFlag() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()

        viewModel.searchQuery = "no such gif"
        try await waitForDebounce()

        XCTAssertTrue(viewModel.isSearchEmpty)
        XCTAssertTrue(viewModel.gifs.isEmpty)
    }

    func testToggleFavoritePersistsReordersAndUpdatesVisibleList() async {
        let favorites = FakeFavoritesManaging()
        let viewModel = makeViewModel(favorites: favorites)
        await viewModel.onAppear()

        await viewModel.toggleFavorite(Gif(id: "1", title: "Excited Cat", width: 200, height: 150))
        XCTAssertEqual(viewModel.favoriteIDs, ["1"])
        XCTAssertEqual(favorites.savedIDs, ["1"])

        await viewModel.toggleFavorite(Gif(id: "2", title: "Thumbs Up", width: 200, height: 190))
        XCTAssertEqual(viewModel.favoriteIDs, ["2", "1"], "most-recently-favorited-first")

        viewModel.selectTab(.favorites)
        try? await waitForBackgroundTask()
        XCTAssertEqual(viewModel.gifs.map(\.id), ["2", "1"])

        await viewModel.toggleFavorite(Gif(id: "2", title: "Thumbs Up", width: 200, height: 190))
        XCTAssertEqual(viewModel.favoriteIDs, ["1"])
        XCTAssertEqual(viewModel.gifs.map(\.id), ["1"], "unfavoriting while on the Favorites tab drops the card immediately")
    }

    func testPaginationBoundaries() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.gifs.count, 8)
        XCTAssertTrue(viewModel.hasMore)

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.gifs.last!)
        try await waitForBackgroundTask()
        XCTAssertEqual(viewModel.gifs.count, 16)
        XCTAssertTrue(viewModel.hasMore)

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.gifs.last!)
        try await waitForBackgroundTask()
        XCTAssertEqual(viewModel.gifs.count, 18)
        XCTAssertFalse(viewModel.hasMore)
    }

    func testSearchOnTrendingCallsProviderSearch() async throws {
        let spy = SpyGifProviding(wrapping: MockGifProvider(latency: .zero))
        let viewModel = makeViewModel(provider: spy)
        await viewModel.onAppear()

        viewModel.searchQuery = "clap"
        try await waitForDebounce()

        XCTAssertGreaterThanOrEqual(spy.searchCallCount, 1)
        XCTAssertEqual(spy.lastSearchQuery, "clap")
        XCTAssertTrue(viewModel.gifs.allSatisfy { $0.title.localizedCaseInsensitiveContains("clap") })
    }

    func testSearchOnFavoritesFiltersClientSideWithoutCallingSearch() async throws {
        let spy = SpyGifProviding(wrapping: MockGifProvider(latency: .zero))
        let viewModel = makeViewModel(provider: spy)
        await viewModel.onAppear()

        await viewModel.toggleFavorite(Gif(id: "7", title: "Clapping Hands", width: 200, height: 230))
        await viewModel.toggleFavorite(Gif(id: "1", title: "Excited Cat", width: 200, height: 150))

        viewModel.selectTab(.favorites)
        try? await waitForBackgroundTask()

        let searchCallsBeforeQuery = spy.searchCallCount
        viewModel.searchQuery = "clap"
        try await waitForDebounce()

        XCTAssertEqual(spy.searchCallCount, searchCallsBeforeQuery, "favorites search must not hit the provider")
        XCTAssertEqual(viewModel.gifs.map(\.id), ["7"])
    }
}
