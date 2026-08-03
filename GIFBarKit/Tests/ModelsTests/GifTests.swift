import XCTest
@testable import Models

final class GifTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let gif = Gif(id: "42", title: "Excited Cat", width: 200, height: 150)
        let data = try JSONEncoder().encode(gif)
        let decoded = try JSONDecoder().decode(Gif.self, from: data)
        XCTAssertEqual(gif, decoded)
    }

    func testEquatableByFullValue() {
        let a = Gif(id: "1", title: "A", width: 200, height: 100)
        let b = Gif(id: "1", title: "A", width: 200, height: 100)
        let differentTitle = Gif(id: "1", title: "B", width: 200, height: 100)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, differentTitle)
    }
}

final class GifPageTests: XCTestCase {
    func testEquatable() {
        let gif = Gif(id: "1", title: "A", width: 200, height: 100)
        let a = GifPage(gifs: [gif], hasMore: true)
        let b = GifPage(gifs: [gif], hasMore: true)
        XCTAssertEqual(a, b)
    }
}
