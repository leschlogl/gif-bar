import Foundation

public struct Gif: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let title: String
    public let width: Int
    public let height: Int
    /// Grid-thumbnail rendition URL, picked by `Networking.GifRenditionPicker`. `nil` for
    /// mock data — `GIFCard` falls back to a placeholder when this is unset.
    public let previewURL: URL?
    /// Full-quality `images.original` URL, used for both clipboard operations
    /// (see docs/decisions/gif-handling.md). `nil` for mock data.
    public let originalURL: URL?

    public init(id: String, title: String, width: Int, height: Int, previewURL: URL? = nil, originalURL: URL? = nil) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.previewURL = previewURL
        self.originalURL = originalURL
    }
}
