/// A single GIF object as returned by any Giphy endpoint (trending/search/id-lookup all
/// share this shape).
public struct GifDTO: Decodable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let images: ImagesDTO

    public init(id: String, title: String, images: ImagesDTO) {
        self.id = id
        self.title = title
        self.images = images
    }
}
