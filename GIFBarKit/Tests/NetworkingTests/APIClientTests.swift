import XCTest
@testable import Networking

private struct FakeAPIRequesting: APIRequesting {
    var result: Result<(Data, URLResponse), Error>

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

private struct Payload: Codable, Equatable {
    let value: String
}

final class APIClientTests: XCTestCase {
    private let url = URL(string: "https://api.giphy.com/v1/gifs/trending")!

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    func testFetchDecodesSuccessfulResponse() async throws {
        let data = try JSONEncoder().encode(Payload(value: "hello"))
        let session = FakeAPIRequesting(result: .success((data, httpResponse(statusCode: 200))))
        let client = APIClient(apiKey: "test-key", session: session)

        let payload: Payload = try await client.fetch(.trending(offset: 0, limit: 10))

        XCTAssertEqual(payload, Payload(value: "hello"))
    }

    func testFetchThrowsHTTPStatusOnNon2xx() async {
        let session = FakeAPIRequesting(result: .success((Data(), httpResponse(statusCode: 403))))
        let client = APIClient(apiKey: "test-key", session: session)

        do {
            let _: Payload = try await client.fetch(.trending(offset: 0, limit: 10))
            XCTFail("expected httpStatus error")
        } catch NetworkError.httpStatus(let code) {
            XCTAssertEqual(code, 403)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testFetchThrowsDecodingFailedOnMalformedJSON() async {
        let data = Data("not json".utf8)
        let session = FakeAPIRequesting(result: .success((data, httpResponse(statusCode: 200))))
        let client = APIClient(apiKey: "test-key", session: session)

        do {
            let _: Payload = try await client.fetch(.trending(offset: 0, limit: 10))
            XCTFail("expected decodingFailed error")
        } catch NetworkError.decodingFailed {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testFetchThrowsRequestFailedOnTransportError() async {
        struct DummyError: Error {}
        let session = FakeAPIRequesting(result: .failure(DummyError()))
        let client = APIClient(apiKey: "test-key", session: session)

        do {
            let _: Payload = try await client.fetch(.trending(offset: 0, limit: 10))
            XCTFail("expected requestFailed error")
        } catch NetworkError.requestFailed {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
