import AppKit
import Models

/// Both operations always use the GIF's full-quality `original` rendition, never the
/// downsized grid rendition — see docs/decisions/gif-handling.md. The URL synthesis
/// below is a mock-only convention (see that doc) until real Networking supplies
/// `images.original.url`.
public struct ClipboardService: ClipboardCopying {
    /// A minimal valid 1x1 transparent GIF, standing in for a real downloaded GIF
    /// until Networking can fetch the actual binary.
    private static let placeholderGIFData = Data(
        base64Encoded: "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBTAA7"
    )!

    private let provider: GifProviding
    private let pasteboard: PasteboardWriting

    public init(provider: GifProviding, pasteboard: PasteboardWriting = NSPasteboard.general) {
        self.provider = provider
        self.pasteboard = pasteboard
    }

    public func copyURL(gifID: String) async throws {
        try await fetchGif(id: gifID)
        let urlString = "https://giphy.com/gifs/\(gifID)"
        await MainActor.run {
            pasteboard.clearContents()
            pasteboard.setString(urlString, forType: .string)
        }
    }

    public func copyBinary(gifID: String) async throws {
        try await fetchGif(id: gifID)
        await MainActor.run {
            pasteboard.clearContents()
            pasteboard.setData(Self.placeholderGIFData, forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
        }
    }

    @discardableResult
    private func fetchGif(id: String) async throws -> Gif {
        guard let gif = try await provider.fetch(ids: [id]).first else {
            throw ClipboardServiceError.gifNotFound(id)
        }
        return gif
    }
}
