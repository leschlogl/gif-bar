/// A single GIF object as returned by any Giphy endpoint (trending/search/id-lookup all
/// share this shape).
public struct GifDTO: Decodable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let images: ImagesDTO
    /// Giphy-authored accessibility description, distinct from `title` — meant for
    /// screen readers specifically. Often present but empty (`""`) rather than absent.
    public let altText: String?

    public init(id: String, title: String, images: ImagesDTO, altText: String? = nil) {
        self.id = id
        self.title = title
        self.images = images
        self.altText = altText
    }
}
