import XCTest
@testable import Services
import Persistence

private actor FakeFavoritesStore: FavoritesStore {
    private var ids: [String]

    init(ids: [String] = []) {
        self.ids = ids
    }

    func loadFavoriteIDs() async -> [String] { ids }

    func save(favoriteIDs: [String]) async {
        ids = favoriteIDs
    }
}

final class FavoritesServiceTests: XCTestCase {
    func testLoadDelegatesToStore() async {
        let store = FakeFavoritesStore(ids: ["3", "1"])
        let service = FavoritesService(store: store)

        let ids = await service.loadFavoriteIDs()

        XCTAssertEqual(ids, ["3", "1"])
    }

    func testSetDelegatesToStore() async {
        let store = FakeFavoritesStore()
        let service = FavoritesService(store: store)

        await service.setFavoriteIDs(["7", "8"])

        let ids = await store.loadFavoriteIDs()
        XCTAssertEqual(ids, ["7", "8"])
    }
}
