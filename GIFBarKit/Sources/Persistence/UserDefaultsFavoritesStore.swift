import Foundation

public struct UserDefaultsFavoritesStore: FavoritesStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "com.leschlogl.GIFBar.favoriteIDs") {
        self.defaults = defaults
        self.key = key
    }

    public func loadFavoriteIDs() async -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    public func save(favoriteIDs: [String]) async {
        defaults.set(favoriteIDs, forKey: key)
    }
}
