import Foundation

/// Picks the smallest Giphy rendition that still looks sharp at a masonry cell's
/// rendered size — never `original`. See "Rendition selection for the masonry grid" in
/// docs/decisions/gif-handling.md for the full rationale and thresholds.
public enum GifRenditionPicker {
    private static let smallThreshold: CGFloat = 110

    /// - Parameters:
    ///   - images: the GIF's decoded rendition set.
    ///   - targetWidth: the cell's rendered width, in points.
    ///   - scale: the display's scale factor (2x/3x on Retina).
    public static func rendition(for images: ImagesDTO, targetWidth: CGFloat, scale: CGFloat) -> RenditionDTO? {
        let targetPixelWidth = targetWidth * scale
        if targetPixelWidth <= smallThreshold {
            return images.fixedWidthSmall ?? images.fixedWidth ?? images.fixedWidthDownsampled
        }
        // Above ~220px, cap at `fixed_width` quality rather than falling through to
        // `original` — `fixed_width_downsampled` is only used when the caller explicitly
        // prioritizes bandwidth (e.g. scroll-ahead prefetch), not based on target width.
        return images.fixedWidth ?? images.fixedWidthDownsampled ?? images.fixedWidthSmall
    }
}
