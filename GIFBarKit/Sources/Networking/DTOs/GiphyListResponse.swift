/// Envelope shared by every Giphy list-producing endpoint (trending, search, id-lookup).
public struct GiphyListResponse: Decodable, Sendable, Equatable {
    public let data: [GifDTO]
    public let pagination: PaginationDTO?

    public init(data: [GifDTO], pagination: PaginationDTO?) {
        self.data = data
        self.pagination = pagination
    }
}

public struct PaginationDTO: Decodable, Sendable, Equatable {
    public let totalCount: Int
    public let count: Int
    public let offset: Int

    public init(totalCount: Int, count: Int, offset: Int) {
        self.totalCount = totalCount
        self.count = count
        self.offset = offset
    }
}
