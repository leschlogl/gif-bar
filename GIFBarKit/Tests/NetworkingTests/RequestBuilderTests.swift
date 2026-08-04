import XCTest
@testable import Networking

final class RequestBuilderTests: XCTestCase {
    private let baseURL = URL(string: "https://api.giphy.com/v1/gifs")!

    func testTrendingRequestIncludesAPIKeyOffsetAndLimit() throws {
        let builder = RequestBuilder(baseURL: baseURL, apiKey: "test-key")
        let request = try builder.request(for: .trending(offset: 20, limit: 25))

        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v1/gifs/trending")
        XCTAssertQueryItem(components, name: "api_key", value: "test-key")
        XCTAssertQueryItem(components, name: "offset", value: "20")
        XCTAssertQueryItem(components, name: "limit", value: "25")
    }

    func testSearchRequestIncludesQuery() throws {
        let builder = RequestBuilder(baseURL: baseURL, apiKey: "test-key")
        let request = try builder.request(for: .search(query: "cat", offset: 0, limit: 10))

        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v1/gifs/search")
        XCTAssertQueryItem(components, name: "q", value: "cat")
    }

    func testByIDsRequestHasNoSubPath() throws {
        let builder = RequestBuilder(baseURL: baseURL, apiKey: "test-key")
        let request = try builder.request(for: .byIDs(["1", "2", "3"]))

        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v1/gifs")
        XCTAssertQueryItem(components, name: "ids", value: "1,2,3")
    }

    private func XCTAssertQueryItem(
        _ components: URLComponents,
        name: String,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = components.queryItems?.first { $0.name == name }?.value
        XCTAssertEqual(actual, value, "expected query item \(name)=\(value)", file: file, line: line)
    }
}
