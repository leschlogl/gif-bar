import Services

private struct InMemoryFavoritesManaging: FavoritesManaging {
    func loadFavoriteIDs() async -> [String] { [] }
    func setFavoriteIDs(_ ids: [String]) async {}
}

extension GifBarViewModel {
    public static func preview() -> GifBarViewModel {
        let provider = MockGifProvider(latency: .zero)
        return GifBarViewModel(
            provider: provider,
            clipboard: ClipboardService(provider: provider),
            favorites: InMemoryFavoritesManaging()
        )
    }
}
