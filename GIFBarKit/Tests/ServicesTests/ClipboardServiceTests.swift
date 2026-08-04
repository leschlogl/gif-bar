import AppKit
import XCTest
@testable import Services
import Models
import Networking

private final class FakePasteboard: PasteboardWriting, @unchecked Sendable {
    private(set) var clearCount = 0
    private(set) var lastString: (value: String, type: NSPasteboard.PasteboardType)?
    private(set) var lastData: (value: Data?, type: NSPasteboard.PasteboardType)?

    func clearContents() -> Int {
        clearCount += 1
        return clearCount
    }

    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        lastString = (string, dataType)
        return true
    }

    func setData(_ data: Data?, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        lastData = (data, dataType)
        return true
    }
}

private struct FakeGifProviding: GifProviding {
    var gifsByID: [String: Gif]

    func trending(offset: Int, limit: Int) async throws -> GifPage { GifPage(gifs: [], hasMore: false) }
    func search(query: String, offset: Int, limit: Int) async throws -> GifPage { GifPage(gifs: [], hasMore: false) }

    func fetch(ids: [String]) async throws -> [Gif] {
        ids.compactMap { gifsByID[$0] }
    }
}

private final class FakeImageLoading: ImageLoading, @unchecked Sendable {
    var dataByURL: [URL: Data] = [:]
    private(set) var requestedURLs: [URL] = []

    func data(for url: URL) async throws -> Data {
        requestedURLs.append(url)
        guard let data = dataByURL[url] else {
            struct NotFound: Error {}
            throw NotFound()
        }
        return data
    }
}

final class ClipboardServiceTests: XCTestCase {
    private let originalURL = URL(string: "https://media.giphy.com/1/original.gif")!

    private func makeService(
        pasteboard: FakePasteboard,
        imageLoader: FakeImageLoading = FakeImageLoading(),
        gifsByID: [String: Gif] = [:]
    ) -> ClipboardService {
        ClipboardService(provider: FakeGifProviding(gifsByID: gifsByID), imageLoader: imageLoader, pasteboard: pasteboard)
    }

    func testCopyURLWritesOriginalURLString() async throws {
        let pasteboard = FakePasteboard()
        let gif = Gif(id: "1", title: "Cat", width: 200, height: 150, originalURL: originalURL)
        let service = makeService(pasteboard: pasteboard, gifsByID: ["1": gif])

        try await service.copyURL(gifID: "1")

        XCTAssertEqual(pasteboard.clearCount, 1)
        XCTAssertEqual(pasteboard.lastString?.value, originalURL.absoluteString)
        XCTAssertEqual(pasteboard.lastString?.type, .string)
    }

    func testCopyBinaryWritesDownloadedOriginalBytes() async throws {
        let pasteboard = FakePasteboard()
        let imageLoader = FakeImageLoading()
        imageLoader.dataByURL[originalURL] = Data("gif-bytes".utf8)
        let gif = Gif(id: "1", title: "Cat", width: 200, height: 150, originalURL: originalURL)
        let service = makeService(pasteboard: pasteboard, imageLoader: imageLoader, gifsByID: ["1": gif])

        try await service.copyBinary(gifID: "1")

        XCTAssertEqual(pasteboard.clearCount, 1)
        XCTAssertEqual(pasteboard.lastData?.value, Data("gif-bytes".utf8))
        XCTAssertEqual(pasteboard.lastData?.type, NSPasteboard.PasteboardType("com.compuserve.gif"))
        XCTAssertEqual(imageLoader.requestedURLs, [originalURL])
    }

    func testCopyURLThrowsForUnknownGif() async {
        let pasteboard = FakePasteboard()
        let service = makeService(pasteboard: pasteboard)

        do {
            try await service.copyURL(gifID: "does-not-exist")
            XCTFail("expected gifNotFound to be thrown")
        } catch ClipboardServiceError.gifNotFound(let id) {
            XCTAssertEqual(id, "does-not-exist")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testCopyURLThrowsWhenOriginalURLMissing() async {
        let pasteboard = FakePasteboard()
        let gif = Gif(id: "1", title: "Cat", width: 200, height: 150)
        let service = makeService(pasteboard: pasteboard, gifsByID: ["1": gif])

        do {
            try await service.copyURL(gifID: "1")
            XCTFail("expected missingOriginalURL to be thrown")
        } catch ClipboardServiceError.missingOriginalURL(let id) {
            XCTAssertEqual(id, "1")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testCopyBinaryThrowsWhenOriginalURLMissing() async {
        let pasteboard = FakePasteboard()
        let gif = Gif(id: "1", title: "Cat", width: 200, height: 150)
        let service = makeService(pasteboard: pasteboard, gifsByID: ["1": gif])

        do {
            try await service.copyBinary(gifID: "1")
            XCTFail("expected missingOriginalURL to be thrown")
        } catch ClipboardServiceError.missingOriginalURL(let id) {
            XCTAssertEqual(id, "1")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
