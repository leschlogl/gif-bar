import AppKit
import XCTest
@testable import Services

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

final class ClipboardServiceTests: XCTestCase {
    private func makeService(pasteboard: FakePasteboard) -> ClipboardService {
        ClipboardService(provider: MockGifProvider(latency: .zero), pasteboard: pasteboard)
    }

    func testCopyURLWritesGiphyURLString() async throws {
        let pasteboard = FakePasteboard()
        let service = makeService(pasteboard: pasteboard)

        try await service.copyURL(gifID: "1")

        XCTAssertEqual(pasteboard.clearCount, 1)
        XCTAssertEqual(pasteboard.lastString?.value, "https://giphy.com/gifs/1")
        XCTAssertEqual(pasteboard.lastString?.type, .string)
    }

    func testCopyBinaryWritesGIFData() async throws {
        let pasteboard = FakePasteboard()
        let service = makeService(pasteboard: pasteboard)

        try await service.copyBinary(gifID: "1")

        XCTAssertEqual(pasteboard.clearCount, 1)
        XCTAssertNotNil(pasteboard.lastData?.value)
        XCTAssertEqual(pasteboard.lastData?.type, NSPasteboard.PasteboardType("com.compuserve.gif"))
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
}
