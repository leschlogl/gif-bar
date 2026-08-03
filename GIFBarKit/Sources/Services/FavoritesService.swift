import Persistence

/// Lets `ViewModels` manage favorites without depending on `Persistence` directly —
/// the module graph only allows `ViewModels` to depend on `Services`.
public struct FavoritesService: FavoritesManaging {
    private let store: FavoritesStore

    public init(store: FavoritesStore) {
        self.store = store
    }

    public func loadFavoriteIDs() async -> [String] {
        await store.loadFavoriteIDs()
    }

    public func setFavoriteIDs(_ ids: [String]) async {
        await store.save(favoriteIDs: ids)
    }
}
