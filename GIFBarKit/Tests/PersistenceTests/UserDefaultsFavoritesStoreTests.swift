import XCTest
@testable import Persistence

final class UserDefaultsFavoritesStoreTests: XCTestCase {
    private func makeStore() -> UserDefaultsFavoritesStore {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        return UserDefaultsFavoritesStore(defaults: defaults, key: "favoriteIDs")
    }

    func testLoadDefaultsToEmpty() async {
        let store = makeStore()
        let ids = await store.loadFavoriteIDs()
        XCTAssertEqual(ids, [])
    }

    func testSaveThenLoadRoundTrips() async {
        let store = makeStore()
        await store.save(favoriteIDs: ["3", "1", "2"])
        let ids = await store.loadFavoriteIDs()
        XCTAssertEqual(ids, ["3", "1", "2"])
    }

    func testSaveOverwritesPreviousValue() async {
        let store = makeStore()
        await store.save(favoriteIDs: ["1"])
        await store.save(favoriteIDs: ["2", "3"])
        let ids = await store.loadFavoriteIDs()
        XCTAssertEqual(ids, ["2", "3"])
    }
}
