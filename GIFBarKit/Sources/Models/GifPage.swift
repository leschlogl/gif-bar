public struct GifPage: Sendable, Equatable {
    public let gifs: [Gif]
    public let hasMore: Bool

    public init(gifs: [Gif], hasMore: Bool) {
        self.gifs = gifs
        self.hasMore = hasMore
    }
}
