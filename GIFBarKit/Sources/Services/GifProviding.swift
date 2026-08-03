import Models

public protocol GifProviding: Sendable {
    func trending(offset: Int, limit: Int) async throws -> GifPage
    func search(query: String, offset: Int, limit: Int) async throws -> GifPage
    func fetch(ids: [String]) async throws -> [Gif]
}
