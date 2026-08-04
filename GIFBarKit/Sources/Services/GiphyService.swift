import Models
import Networking

/// The real `GifProviding` implementation, calling through `Networking.APIClient` to the
/// Giphy REST API. See `Services.MockGifProvider` for the mock this replaces.
public struct GiphyService: GifProviding {
    private static let maxIDsPerBatch = 50

    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func trending(offset: Int, limit: Int) async throws -> GifPage {
        let response: GiphyListResponse = try await apiClient.fetch(.trending(offset: offset, limit: limit))
        return response.toGifPage()
    }

    public func search(query: String, offset: Int, limit: Int) async throws -> GifPage {
        let response: GiphyListResponse = try await apiClient.fetch(.search(query: query, offset: offset, limit: limit))
        return response.toGifPage()
    }

    /// Giphy's id-lookup endpoint takes ≤50 ids per call and returns matches in its own
    /// order — chunk client-side and reorder to match the requested order, dropping
    /// unknown ids, mirroring `MockGifProvider.fetch(ids:)`'s contract exactly (this is
    /// what preserves Favorites' most-recently-favorited-first ordering).
    public func fetch(ids: [String]) async throws -> [Gif] {
        guard !ids.isEmpty else { return [] }

        var gifsByID: [String: Gif] = [:]
        for chunk in ids.chunked(into: Self.maxIDsPerBatch) {
            let response: GiphyListResponse = try await apiClient.fetch(.byIDs(chunk))
            for dto in response.data {
                gifsByID[dto.id] = dto.toModel()
            }
        }
        return ids.compactMap { gifsByID[$0] }
    }
}

extension Array {
    fileprivate func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
