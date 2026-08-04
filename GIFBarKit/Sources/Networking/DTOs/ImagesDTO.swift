/// The subset of Giphy's `images` dictionary GIFBar actually uses. See
/// docs/decisions/gif-handling.md for the full rendition list and why only these four
/// are decoded. All optional since Giphy's own schema doesn't guarantee every rendition
/// exists for every GIF.
public struct ImagesDTO: Decodable, Sendable, Equatable {
    public let fixedWidthSmall: RenditionDTO?
    public let fixedWidth: RenditionDTO?
    public let fixedWidthDownsampled: RenditionDTO?
    public let original: RenditionDTO?

    public init(
        fixedWidthSmall: RenditionDTO?,
        fixedWidth: RenditionDTO?,
        fixedWidthDownsampled: RenditionDTO?,
        original: RenditionDTO?
    ) {
        self.fixedWidthSmall = fixedWidthSmall
        self.fixedWidth = fixedWidth
        self.fixedWidthDownsampled = fixedWidthDownsampled
        self.original = original
    }
}
