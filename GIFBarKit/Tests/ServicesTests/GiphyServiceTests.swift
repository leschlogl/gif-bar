import XCTest
@testable import Services
import Networking

private struct FakeAPIRequesting: APIRequesting {
    var responses: [(Data, URLResponse)]
    private let box = ResponseBox()

    init(responses: [(Data, URLResponse)]) {
        self.responses = responses
        box.remaining = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        box.next()
    }

    private final class ResponseBox: @unchecked Sendable {
        var remaining: [(Data, URLResponse)] = []
        func next() -> (Data, URLResponse) {
            precondition(!remaining.isEmpty, "no more fake responses queued")
            return remaining.removeFirst()
        }
    }
}

private func makeResponse(statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.giphy.com/v1/gifs")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func listResponseJSON(ids: [String], totalCount: Int, offset: Int) -> Data {
    let items = ids.map { id in
        """
        {
            "id": "\(id)",
            "title": "Gif \(id)",
            "images": {
                "fixed_width": { "url": "https://media.giphy.com/\(id)/fixed_width.gif", "width": "200", "height": "150" },
                "original": { "url": "https://media.giphy.com/\(id)/original.gif", "width": "480", "height": "360" }
            }
        }
        """
    }.joined(separator: ",")
    let json = """
    {
        "data": [\(items)],
        "pagination": { "total_count": \(totalCount), "count": \(ids.count), "offset": \(offset) }
    }
    """
    return Data(json.utf8)
}

final class GiphyServiceTests: XCTestCase {
    private func makeService(responses: [(Data, URLResponse)]) -> GiphyService {
        let apiClient = APIClient(apiKey: "test-key", session: FakeAPIRequesting(responses: responses))
        return GiphyService(apiClient: apiClient)
    }

    func testTrendingDecodesGifsAndHasMore() async throws {
        let data = listResponseJSON(ids: ["1", "2"], totalCount: 10, offset: 0)
        let service = makeService(responses: [(data, makeResponse())])

        let page = try await service.trending(offset: 0, limit: 2)

        XCTAssertEqual(page.gifs.map(\.id), ["1", "2"])
        XCTAssertEqual(page.gifs.first?.previewURL, URL(string: "https://media.giphy.com/1/fixed_width.gif"))
        XCTAssertEqual(page.gifs.first?.originalURL, URL(string: "https://media.giphy.com/1/original.gif"))
        XCTAssertTrue(page.hasMore)
    }

    func testSearchLastPageHasNoMore() async throws {
        let data = listResponseJSON(ids: ["1"], totalCount: 1, offset: 0)
        let service = makeService(responses: [(data, makeResponse())])

        let page = try await service.search(query: "cat", offset: 0, limit: 10)

        XCTAssertFalse(page.hasMore)
    }

    func testFetchReordersToMatchRequestedIDsAndDropsUnknown() async throws {
        // Giphy returns matches in its own order — service must reorder to match the request.
        let data = listResponseJSON(ids: ["2", "1"], totalCount: 2, offset: 0)
        let service = makeService(responses: [(data, makeResponse())])

        let gifs = try await service.fetch(ids: ["1", "missing", "2"])

        XCTAssertEqual(gifs.map(\.id), ["1", "2"])
    }

    func testFetchEmptyIDsMakesNoRequest() async throws {
        let service = makeService(responses: [])
        let gifs = try await service.fetch(ids: [])
        XCTAssertEqual(gifs, [])
    }

    func testFetchChunksMoreThan50IDs() async throws {
        let firstBatchIDs = (1...50).map(String.init)
        let secondBatchIDs = (51...60).map(String.init)
        let responses: [(Data, URLResponse)] = [
            (listResponseJSON(ids: firstBatchIDs, totalCount: 50, offset: 0), makeResponse()),
            (listResponseJSON(ids: secondBatchIDs, totalCount: 10, offset: 0), makeResponse()),
        ]
        let service = makeService(responses: responses)

        let gifs = try await service.fetch(ids: firstBatchIDs + secondBatchIDs)

        XCTAssertEqual(gifs.count, 60)
        XCTAssertEqual(gifs.first?.id, "1")
        XCTAssertEqual(gifs.last?.id, "60")
    }

    func testTrendingPropagatesNetworkError() async {
        let service = makeService(responses: [(Data(), makeResponse(statusCode: 500))])

        do {
            _ = try await service.trending(offset: 0, limit: 10)
            XCTFail("expected NetworkError.httpStatus")
        } catch NetworkError.httpStatus(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
