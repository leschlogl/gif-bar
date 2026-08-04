import Foundation

/// A path relative to `RequestBuilder`'s base URL, plus its query items.
/// `api_key` is injected separately by `RequestBuilder` — endpoints never carry it themselves.
public struct Endpoint: Sendable, Equatable {
    public let path: String
    public let queryItems: [URLQueryItem]

    public init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }
}

extension Endpoint {
    public static func trending(offset: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "trending",
            queryItems: [
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
    }

    public static func search(query: String, offset: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
    }

    /// Giphy's ID-lookup endpoint lives at the base `/v1/gifs` path itself (no sub-path),
    /// unlike `trending`/`search`. Chunking into ≤50-ID batches is the caller's responsibility
    /// (see docs/decisions/gif-handling.md).
    public static func byIDs(_ ids: [String]) -> Endpoint {
        Endpoint(
            path: "",
            queryItems: [
                URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            ]
        )
    }
}
