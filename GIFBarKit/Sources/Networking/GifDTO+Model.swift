import CoreGraphics
import Models

/// The popover's masonry grid is fixed at 2 columns inside a non-resizable 380pt-wide
/// popover (`DesignTokens.Layout`: 380 - 2×16 padding - 1×12 gutter, ÷ 2 columns ≈ 168pt).
/// `Networking` can't depend on `DesignSystem` (see CLAUDE.md's module graph), so this is
/// duplicated here as the default target for picking a GIF's grid preview rendition at
/// decode time — keep in sync if those layout tokens ever change.
private let defaultGridCardWidth: CGFloat = 168
private let defaultDisplayScale: CGFloat = 2

extension GifDTO {
    /// Uses the picked preview rendition's own width/height for aspect ratio (not
    /// `images.original`'s dimensions) per "Rendition selection for the masonry grid" in
    /// docs/decisions/gif-handling.md.
    public func toModel() -> Gif {
        let previewRendition = GifRenditionPicker.rendition(
            for: images,
            targetWidth: defaultGridCardWidth,
            scale: defaultDisplayScale
        )
        let dimensions = previewRendition ?? images.original
        // Giphy returns "" (present but empty) far more often than omitting the field
        // outright — normalize that to nil here so callers can just do
        // `gif.altText ?? gif.title` without re-checking for blankness themselves.
        let normalizedAltText = altText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Gif(
            id: id,
            title: title,
            width: dimensions?.width ?? 0,
            height: dimensions?.height ?? 0,
            previewURL: previewRendition?.url,
            originalURL: images.original?.url,
            altText: (normalizedAltText?.isEmpty ?? true) ? nil : normalizedAltText
        )
    }
}

extension GiphyListResponse {
    public func toGifPage() -> GifPage {
        let gifs = data.map { $0.toModel() }
        // Giphy's `total_count` is a known-unreliable estimate — trusting it alone can
        // claim more pages exist forever once the API actually starts returning empty
        // pages at the same offset. An empty page is a reliable "no more" signal on its
        // own, regardless of what `total_count` says.
        guard let pagination, !gifs.isEmpty else {
            return GifPage(gifs: gifs, hasMore: false)
        }
        let hasMore = pagination.offset + pagination.count < pagination.totalCount
        return GifPage(gifs: gifs, hasMore: hasMore)
    }
}
