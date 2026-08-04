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
    /// Ordered, most-recently-favorited-first.
    public private(set) var favoriteIDs: [String] = []
    public var selectedGifID: String?
    public private(set) var toast: ToastMessage?
    public private(set) var isLaunchAtLoginEnabled: Bool

    public var isErrorState: Bool { !isLoading && lastLoadFailed }
    public var isFavoritesEmpty: Bool { tab == .favorites && !isLoading && !isErrorState && favoriteIDs.isEmpty }
    public var isSearchEmpty: Bool { !isErrorState && !searchQuery.isEmpty && !isLoading && gifs.isEmpty && !isFavoritesEmpty }
    public var isGridVisible: Bool { !isLoading && !isErrorState && !isFavoritesEmpty && !isSearchEmpty }

    private let provider: GifProviding
    private let clipboard: ClipboardCopying
    private let favorites: FavoritesManaging
    private let imageLoader: ImageDataLoading
    private let launchAtLogin: LaunchAtLoginManaging
    private let appLifecycle: AppLifecycleControlling

    private var offset = 0
    private var lastLoadFailed = false
    /// Bumped by every `reload()`; a `reload()`/`loadNextPage()` call only applies its
    /// result if this hasn't moved on since it started — guards against a stale request
    /// (e.g. a pagination fetch in flight when a new search fires) landing late and
    /// corrupting the current list.
    private var loadGeneration = 0
    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    private var loadTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    public init(
        provider: GifProviding,
        clipboard: ClipboardCopying,
        favorites: FavoritesManaging,
        imageLoader: ImageDataLoading = UnavailableImageDataLoading(),
        launchAtLogin: LaunchAtLoginManaging = SMAppServiceLaunchAtLogin(),
        appLifecycle: AppLifecycleControlling = NSApplicationLifecycleController()
    ) {
        self.provider = provider
        self.clipboard = clipboard
        self.favorites = favorites
        self.imageLoader = imageLoader
        self.launchAtLogin = launchAtLogin
        self.appLifecycle = appLifecycle
        self.isLaunchAtLoginEnabled = launchAtLogin.isEnabled

        searchCancellable = searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reloadNow()
            }
    }

    public func onAppear() async {
        guard gifs.isEmpty, favoriteIDs.isEmpty else { return }
        favoriteIDs = await favorites.loadFavoriteIDs()
        await reload(generation: nextGeneration())
    }

    public func selectTab(_ newTab: Tab) {
        tab = newTab
    }

    public func retryLoad() {
        reloadNow()
    }

    public func loadNextPageIfNeeded(currentItem: Gif) {
        guard tab == .trending, hasMore, !isLoading, !isLoadingMore else { return }
        guard gifs.last?.id == currentItem.id else { return }
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
        handleCopySuccess(toast: .gifCopied)
    }

    public func copyURL(_ gif: Gif) async {
        guard (try? await clipboard.copyURL(gifID: gif.id)) != nil else { return }
        handleCopySuccess(toast: .linkCopied)
    }

    /// Fetches a grid thumbnail's raw bytes for `AnimatedGIFView` — the `Views` layer
    /// can't import `Networking`/`Services` directly, so it calls through here instead.
    public func loadImageData(for url: URL) async throws -> Data {
        try await imageLoader.data(for: url)
    }

    public func toggleLaunchAtLogin() {
        do {
            try launchAtLogin.setEnabled(!isLaunchAtLoginEnabled)
            isLaunchAtLoginEnabled = launchAtLogin.isEnabled
        } catch {
            // Leave state unchanged on failure — matches the silent-failure style
            // already used by copyGif/copyURL for this class of non-critical action.
        }
    }

    public func showAboutPanel() {
        appLifecycle.showAboutPanel()
    }

    public func quitApp() {
        appLifecycle.terminate()
    }

    // MARK: - Loading

    /// Cancels any in-flight load and returns a token for the caller's own load — bump
    /// happens synchronously so a `loadNextPage()` already running gets invalidated too.
    private func nextGeneration() -> Int {
        loadTask?.cancel()
        loadGeneration += 1
        return loadGeneration
    }

    private func reloadNow() {
        let generation = nextGeneration()
        loadTask = Task { [weak self] in
            await self?.reload(generation: generation)
        }
    }

    private func reload(generation: Int) async {
        selectedGifID = nil
        offset = 0
        isLoading = true
        // A reload always supersedes any in-flight pagination fetch (see `nextGeneration()`),
        // so clear its spinner here rather than leaving it stuck on — that fetch's own
        // completion won't touch this flag once its generation is stale.
        isLoadingMore = false
        lastLoadFailed = false

        do {
            switch tab {
            case .trending:
                let page = searchQuery.isEmpty
                    ? try await provider.trending(offset: 0, limit: Self.pageSize)
                    : try await provider.search(query: searchQuery, offset: 0, limit: Self.pageSize)
                guard generation == loadGeneration else { return }
                gifs = page.gifs
                offset = page.gifs.count
                hasMore = page.hasMore
            case .favorites:
                let fetched = try await provider.fetch(ids: favoriteIDs)
                guard generation == loadGeneration else { return }
                let ordered = order(fetched, by: favoriteIDs)
                gifs = searchQuery.isEmpty
                    ? ordered
                    : ordered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
                hasMore = false
            }
            isLoading = false
        } catch {
            guard generation == loadGeneration else { return }
            gifs = []
            hasMore = false
            lastLoadFailed = true
            isLoading = false
        }
    }

    private func loadNextPage() {
        isLoadingMore = true
        let generation = loadGeneration
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let page = self.searchQuery.isEmpty
                    ? try await self.provider.trending(offset: self.offset, limit: Self.pageSize)
                    : try await self.provider.search(query: self.searchQuery, offset: self.offset, limit: Self.pageSize)
                guard generation == self.loadGeneration else { return }
                self.gifs.append(contentsOf: page.gifs)
                self.offset += page.gifs.count
                self.hasMore = page.hasMore
                self.isLoadingMore = false
            } catch {
                guard generation == self.loadGeneration else { return }
                // Unlike `reload()`, a pagination failure leaves already-loaded gifs on
                // screen — surfacing `ErrorStateView` here would hide valid content, so
                // this just stops pagination silently rather than setting `lastLoadFailed`.
                self.hasMore = false
                self.isLoadingMore = false
            }
        }
    }

    private func order(_ gifs: [Gif], by ids: [String]) -> [Gif] {
        let byID = Dictionary(uniqueKeysWithValues: gifs.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    // MARK: - Copy / favorite feedback

    private func handleCopySuccess(toast: ToastMessage.Kind) {
        selectedGifID = nil
        showToast(toast)
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

/// Default `imageLoader` for call sites that don't render thumbnails (tests, previews
/// using mock data with a `nil` `previewURL`) — the real `Networking.ImageCache` isn't
/// reachable here since `ViewModels` can't import `Networking`.
public struct UnavailableImageDataLoading: ImageDataLoading {
    public init() {}

    public func data(for url: URL) async throws -> Data {
        throw URLError(.unknown)
    }
}
