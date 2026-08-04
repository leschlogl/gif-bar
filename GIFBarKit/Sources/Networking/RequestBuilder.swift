import Foundation

/// Assembles `URLRequest`s against the Giphy REST API, injecting the `api_key` query
/// param on every request. The key itself is supplied by the caller (see `GiphyAPIKey`
/// for reading it out of `Bundle.main` at the app's composition root) rather than read
/// directly here, so this stays unit-testable outside of an app bundle context.
public struct RequestBuilder: Sendable {
    public static let defaultBaseURL = URL(string: "https://api.giphy.com/v1/gifs")!

    private let baseURL: URL
    private let apiKey: String

    public init(baseURL: URL = RequestBuilder.defaultBaseURL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public func request(for endpoint: Endpoint) throws -> URLRequest {
        let url = endpoint.path.isEmpty ? baseURL : baseURL.appendingPathComponent(endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)] + endpoint.queryItems
        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }
        return URLRequest(url: finalURL)
    }
}
