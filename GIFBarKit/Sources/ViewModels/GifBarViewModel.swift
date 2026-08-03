import Combine
import Foundation
import Models
import Observation
import Services

@Observable
@MainActor
public final class GifBarViewModel {
    public enum Tab: Sendable, Equatable {
        case trending
        case favorites
    }

    private static let pageSize = 8
    private static let prefetchThreshold = 10
    private static let copyFlashDuration: Duration = .milliseconds(900)
    private static let toastDismissDelay: Duration = .milliseconds(1400)

    public private(set) var gifs: [Gif] = []
    public private(set) var isLoading = false
    public private(set) var isLoadingMore = false
    public private(set) var hasMore = true
    public var tab: Tab = .trending {
        didSet {
            guard oldValue != tab else { return }
            gifs = []
            reloadNow()
        }
    }
    public var searchQuery: String = "" {
        didSet {
            guard oldValue != searchQuery else { return }
            searchQuerySubject.send(searchQuery)
        }
    }
    public var isSearchFieldOpen = false
    /// Ordered, most-recently-favorited-first.
    public private(set) var favoriteIDs: [String] = []
    public var selectedGifID: String?
    public private(set) var copiedGifID: String?
    public private(set) var toast: ToastMessage?

    public var isFavoritesEmpty: Bool { tab == .favorites && !isLoading && favoriteIDs.isEmpty }
    public var isSearchEmpty: Bool { !searchQuery.isEmpty && !isLoading && gifs.isEmpty && !isFavoritesEmpty }
    public var isGridVisible: Bool { !isLoading && !isFavoritesEmpty && !isSearchEmpty }

    private let provider: GifProviding
    private let clipboard: ClipboardCopying
    private let favorites: FavoritesManaging

    private var offset = 0
    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    private var loadTask: Task<Void, Never>?
    private var copyFlashTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    public init(provider: GifProviding, clipboard: ClipboardCopying, favorites: FavoritesManaging) {
        self.provider = provider
        self.clipboard = clipboard
        self.favorites = favorites

        searchCancellable = searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.reload()
                }
            }
    }

    public func onAppear() async {
        guard gifs.isEmpty, favoriteIDs.isEmpty else { return }
        favoriteIDs = await favorites.loadFavoriteIDs()
        await reload()
    }

    public func selectTab(_ newTab: Tab) {
        tab = newTab
    }

    public func openSearch() {
        isSearchFieldOpen = true
    }

    public func closeSearch() {
        isSearchFieldOpen = false
        searchQuery = ""
        reloadNow()
    }

    public func loadNextPageIfNeeded(currentItem: Gif) {
        guard tab == .trending, hasMore, !isLoading, !isLoadingMore else { return }
        guard let index = gifs.firstIndex(where: { $0.id == currentItem.id }) else { return }
        guard index >= gifs.count - Self.prefetchThreshold else { return }
        loadNextPage()
    }

    public func toggleFavorite(_ gif: Gif) async {
        let wasFavorited = favoriteIDs.contains(gif.id)
        if wasFavorited {
            favoriteIDs.removeAll { $0 == gif.id }
            if tab == .favorites {
                gifs.removeAll { $0.id == gif.id }
            }
        } else {
            favoriteIDs.insert(gif.id, at: 0)
        }
        await favorites.setFavoriteIDs(favoriteIDs)
        showToast(wasFavorited ? .removedFromFavorites : .addedToFavorites)
    }

    public func selectCard(_ gif: Gif) {
        selectedGifID = selectedGifID == gif.id ? nil : gif.id
    }

    public func copyGif(_ gif: Gif) async {
        guard (try? await clipboard.copyBinary(gifID: gif.id)) != nil else { return }
        handleCopySuccess(gifID: gif.id, toast: .gifCopied)
    }

    public func copyURL(_ gif: Gif) async {
        guard (try? await clipboard.copyURL(gifID: gif.id)) != nil else { return }
        handleCopySuccess(gifID: gif.id, toast: .linkCopied)
    }

    // MARK: - Loading

    private func reloadNow() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.reload()
        }
    }

    private func reload() async {
        selectedGifID = nil
        offset = 0
        isLoading = true
        defer { isLoading = false }

        do {
            switch tab {
            case .trending:
                let page = searchQuery.isEmpty
                    ? try await provider.trending(offset: 0, limit: Self.pageSize)
                    : try await provider.search(query: searchQuery, offset: 0, limit: Self.pageSize)
                gifs = page.gifs
                offset = page.gifs.count
                hasMore = page.hasMore
            case .favorites:
                let fetched = try await provider.fetch(ids: favoriteIDs)
                let ordered = order(fetched, by: favoriteIDs)
                gifs = searchQuery.isEmpty
                    ? ordered
                    : ordered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
                hasMore = false
            }
        } catch {
            gifs = []
            hasMore = false
        }
    }

    private func loadNextPage() {
        isLoadingMore = true
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoadingMore = false }
            do {
                let page = self.searchQuery.isEmpty
                    ? try await self.provider.trending(offset: self.offset, limit: Self.pageSize)
                    : try await self.provider.search(query: self.searchQuery, offset: self.offset, limit: Self.pageSize)
                self.gifs.append(contentsOf: page.gifs)
                self.offset += page.gifs.count
                self.hasMore = page.hasMore
            } catch {
                self.hasMore = false
            }
        }
    }

    private func order(_ gifs: [Gif], by ids: [String]) -> [Gif] {
        let byID = Dictionary(uniqueKeysWithValues: gifs.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    // MARK: - Copy / favorite feedback

    private func handleCopySuccess(gifID: String, toast: ToastMessage.Kind) {
        selectedGifID = nil
        copiedGifID = gifID
        showToast(toast)

        copyFlashTask?.cancel()
        copyFlashTask = Task { [weak self] in
            try? await Task.sleep(for: Self.copyFlashDuration)
            guard !Task.isCancelled, let self, self.copiedGifID == gifID else { return }
            self.copiedGifID = nil
        }
    }

    private func showToast(_ kind: ToastMessage.Kind) {
        let message = ToastMessage(kind: kind)
        toast = message
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: Self.toastDismissDelay)
            guard !Task.isCancelled, let self, self.toast?.id == message.id else { return }
            self.toast = nil
        }
    }
}
