import XCTest
@testable import Views

private struct Item: Identifiable, Equatable {
    let id: Int
    let height: CGFloat
}

final class MasonryBalancerTests: XCTestCase {
    func testDistributesAllItemsAcrossColumns() {
        let items = (0..<9).map { Item(id: $0, height: CGFloat($0 + 1) * 10) }
        let columns = MasonryBalancer.distribute(items, columns: 3) { $0.height }

        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns.flatMap { $0 }.count, items.count)
    }

    func testJoinsShortestColumn() {
        let items = [
            Item(id: 0, height: 100),
            Item(id: 1, height: 10),
            Item(id: 2, height: 10),
        ]
        let columns = MasonryBalancer.distribute(items, columns: 2) { $0.height }

        XCTAssertEqual(columns[0].map(\.id), [0])
        XCTAssertEqual(columns[1].map(\.id), [1, 2])
    }

    func testStableUnderAppend() {
        let base = (0..<10).map { Item(id: $0, height: CGFloat((($0 * 37) % 50) + 20)) }
        let appended = base + (10..<15).map { Item(id: $0, height: CGFloat((($0 * 37) % 50) + 20)) }

        let baseColumns = MasonryBalancer.distribute(base, columns: 2) { $0.height }
        let appendedColumns = MasonryBalancer.distribute(appended, columns: 2) { $0.height }

        func columnIndex(for id: Int, in columns: [[Item]]) -> Int? {
            columns.firstIndex { column in column.contains { $0.id == id } }
        }

        for item in base {
            XCTAssertEqual(
                columnIndex(for: item.id, in: baseColumns),
                columnIndex(for: item.id, in: appendedColumns),
                "item \(item.id) should stay in the same column once already placed"
            )
        }
    }

    func testEmptyItems() {
        let columns = MasonryBalancer.distribute([Item](), columns: 2) { $0.height }
        XCTAssertEqual(columns.count, 2)
        XCTAssertTrue(columns.allSatisfy { $0.isEmpty })
    }

    func testSingleItem() {
        let columns = MasonryBalancer.distribute([Item(id: 0, height: 50)], columns: 2) { $0.height }
        XCTAssertEqual(columns.flatMap { $0 }.count, 1)
    }

    func testSingleColumn() {
        let items = (0..<5).map { Item(id: $0, height: 10) }
        let columns = MasonryBalancer.distribute(items, columns: 1) { $0.height }
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns[0].map(\.id), Array(0..<5))
    }
}
