public protocol FavoritesManaging: Sendable {
    func loadFavoriteIDs() async -> [String]
    func setFavoriteIDs(_ ids: [String]) async
}
