public protocol FavoritesStore: Sendable {
    func loadFavoriteIDs() async -> [String]
    func save(favoriteIDs: [String]) async
}
