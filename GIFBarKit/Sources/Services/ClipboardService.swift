import AppKit
import Models
import Networking

/// Both operations always use the GIF's full-quality `original` rendition, never the
/// downsized grid rendition — see docs/decisions/gif-handling.md.
public struct ClipboardService: ClipboardCopying {
    private let provider: GifProviding
    private let imageLoader: ImageLoading
    private let pasteboard: PasteboardWriting

    public init(provider: GifProviding, imageLoader: ImageLoading = ImageCache(), pasteboard: PasteboardWriting = NSPasteboard.general) {
        self.provider = provider
        self.imageLoader = imageLoader
        self.pasteboard = pasteboard
    }

    public func copyURL(gifID: String) async throws {
        let originalURL = try await fetchOriginalURL(id: gifID)
        await MainActor.run {
            pasteboard.clearContents()
            pasteboard.setString(originalURL.absoluteString, forType: .string)
        }
    }

    public func copyBinary(gifID: String) async throws {
        let originalURL = try await fetchOriginalURL(id: gifID)
        // A cache read/write like any other rendition fetch — reuses bytes already
        // downloaded for this GIF (e.g. a prior copy, or a previously-opened favorite).
        let data = try await imageLoader.data(for: originalURL)
        await MainActor.run {
            pasteboard.clearContents()
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
        }
    }

    private func fetchOriginalURL(id: String) async throws -> URL {
        guard let gif = try await provider.fetch(ids: [id]).first else {
            throw ClipboardServiceError.gifNotFound(id)
        }
        guard let originalURL = gif.originalURL else {
            throw ClipboardServiceError.missingOriginalURL(id)
        }
        return originalURL
    }
}
