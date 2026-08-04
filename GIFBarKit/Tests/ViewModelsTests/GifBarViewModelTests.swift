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

private struct ThrowingGifProviding: GifProviding {
    struct SomeError: Error {}

    func trending(offset: Int, limit: Int) async throws -> GifPage { throw SomeError() }
    func search(query: String, offset: Int, limit: Int) async throws -> GifPage { throw SomeError() }
    func fetch(ids: [String]) async throws -> [Gif] { throw SomeError() }
}

/// Fails until `stopFailing()` is called, so tests can exercise "retry succeeds" flows.
private final class FlakyGifProviding: GifProviding, @unchecked Sendable {
    private let wrapped: GifProviding
    private var shouldFail = true

    init(wrapping: GifProviding) {
        self.wrapped = wrapping
    }

    func stopFailing() {
        shouldFail = false
    }

    func trending(offset: Int, limit: Int) async throws -> GifPage {
        guard !shouldFail else { throw ThrowingGifProviding.SomeError() }
        return try await wrapped.trending(offset: offset, limit: limit)
    }

    func search(query: String, offset: Int, limit: Int) async throws -> GifPage {
        guard !shouldFail else { throw ThrowingGifProviding.SomeError() }
        return try await wrapped.search(query: query, offset: offset, limit: limit)
    }

    func fetch(ids: [String]) async throws -> [Gif] {
        guard !shouldFail else { throw ThrowingGifProviding.SomeError() }
        return try await wrapped.fetch(ids: ids)
    }
}

private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}

/// Delays whichever `trending(offset:limit:)` call matches `gatedOffset` until `gate` is
/// opened, so tests can force two loads to overlap deterministically.
private final class GatedGifProviding: GifProviding, @unchecked Sendable {
    private let wrapped: GifProviding
    let gate = Gate()
    var gatedOffset: Int?

    init(wrapping: GifProviding) {
        self.wrapped = wrapping
    }

    func trending(offset: Int, limit: Int) async throws -> GifPage {
        if offset == gatedOffset { await gate.wait() }
        return try await wrapped.trending(offset: offset, limit: limit)
    }

    func search(query: String, offset: Int, limit: Int) async throws -> GifPage {
        try await wrapped.search(query: query, offset: offset, limit: limit)
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

    func testErrorStateFlagSetWhenInitialLoadFails() async {
        let viewModel = makeViewModel(provider: ThrowingGifProviding())
        await viewModel.onAppear()

        XCTAssertTrue(viewModel.isErrorState)
        XCTAssertTrue(viewModel.gifs.isEmpty)
        XCTAssertFalse(viewModel.isGridVisible)
        XCTAssertFalse(viewModel.isFavoritesEmpty)
        XCTAssertFalse(viewModel.isSearchEmpty)
    }

    func testRetryLoadClearsErrorStateOnceProviderRecovers() async throws {
        let flaky = FlakyGifProviding(wrapping: MockGifProvider(latency: .zero))
        let viewModel = makeViewModel(provider: flaky)
        await viewModel.onAppear()
        XCTAssertTrue(viewModel.isErrorState)

        flaky.stopFailing()
        viewModel.retryLoad()
        try await waitForBackgroundTask()

        XCTAssertFalse(viewModel.isErrorState)
        XCTAssertEqual(viewModel.gifs.count, 8)
        XCTAssertTrue(viewModel.isGridVisible)
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

    func testLoadNextPageIfNeededOnlyTriggersForTheLastItem() async throws {
        let spy = SpyGifProviding(wrapping: MockGifProvider(latency: .zero))
        let viewModel = makeViewModel(provider: spy)
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.gifs.count, 8)

        let callsBefore = spy.trendingCallCount
        viewModel.loadNextPageIfNeeded(currentItem: viewModel.gifs[viewModel.gifs.count - 2])
        try await waitForBackgroundTask()

        XCTAssertEqual(spy.trendingCallCount, callsBefore, "should only prefetch once the last item actually appears, not before")
        XCTAssertEqual(viewModel.gifs.count, 8)
    }

    func testStalePaginationFetchDoesNotCorruptResultsAfterNewSearch() async throws {
        let gated = GatedGifProviding(wrapping: MockGifProvider(latency: .zero))
        let viewModel = makeViewModel(provider: gated)
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.gifs.count, 8)

        gated.gatedOffset = 8
        viewModel.loadNextPageIfNeeded(currentItem: viewModel.gifs.last!)
        try await waitForBackgroundTask()
        XCTAssertTrue(viewModel.isLoadingMore, "pagination fetch should be in flight, parked on the gate")

        viewModel.searchQuery = "clap"
        try await waitForDebounce()

        XCTAssertFalse(viewModel.isLoadingMore, "a new search must clear a stale in-flight pagination spinner")
        let searchResultIDs = viewModel.gifs.map(\.id)
        XCTAssertTrue(viewModel.gifs.allSatisfy { $0.title.localizedCaseInsensitiveContains("clap") })

        await gated.gate.open()
        try await waitForBackgroundTask()

        XCTAssertEqual(
            viewModel.gifs.map(\.id),
            searchResultIDs,
            "the stale pagination fetch resolving late must not append its (unrelated) results onto the new search's list"
        )
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
