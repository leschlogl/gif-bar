import Foundation

/// Fetches and decodes JSON responses from the Giphy REST API.
public struct APIClient: Sendable {
    private let session: APIRequesting
    private let requestBuilder: RequestBuilder
    private let decoder: JSONDecoder

    public init(
        apiKey: String,
        session: APIRequesting = URLSession.shared,
        baseURL: URL = RequestBuilder.defaultBaseURL,
        decoder: JSONDecoder = APIClient.makeDecoder()
    ) {
        self.session = session
        self.requestBuilder = RequestBuilder(baseURL: baseURL, apiKey: apiKey)
        self.decoder = decoder
    }

    public func fetch<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let request = try requestBuilder.request(for: endpoint)
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw NetworkError.requestFailed(error.localizedDescription)
        }
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
