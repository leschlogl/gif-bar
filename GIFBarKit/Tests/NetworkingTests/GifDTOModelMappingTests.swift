import XCTest
@testable import Networking
import Models

final class GifDTOModelMappingTests: XCTestCase {
    func testToModelUsesPreviewRenditionURLAndDimensions() {
        let images = ImagesDTO(
            fixedWidthSmall: RenditionDTO(url: URL(string: "https://example.com/small.gif")!, width: 100, height: 80),
            fixedWidth: RenditionDTO(url: URL(string: "https://example.com/medium.gif")!, width: 200, height: 160),
            fixedWidthDownsampled: nil,
            original: RenditionDTO(url: URL(string: "https://example.com/original.gif")!, width: 480, height: 384)
        )
        let dto = GifDTO(id: "1", title: "Cat", images: images)

        let gif = dto.toModel()

        XCTAssertEqual(gif.id, "1")
        XCTAssertEqual(gif.title, "Cat")
        XCTAssertEqual(gif.originalURL, URL(string: "https://example.com/original.gif"))
        // The default 168pt card width at 2x scale (336px) is above the small threshold,
        // so the picker should land on `fixed_width`, not `original`.
        XCTAssertEqual(gif.previewURL, URL(string: "https://example.com/medium.gif"))
        XCTAssertEqual(gif.width, 200)
        XCTAssertEqual(gif.height, 160)
    }

    func testToModelFallsBackToOriginalDimensionsWhenNoRenditionPicked() {
        let images = ImagesDTO(fixedWidthSmall: nil, fixedWidth: nil, fixedWidthDownsampled: nil, original: RenditionDTO(
            url: URL(string: "https://example.com/original.gif")!,
            width: 480,
            height: 384
        ))
        let dto = GifDTO(id: "1", title: "Cat", images: images)

        let gif = dto.toModel()

        XCTAssertNil(gif.previewURL)
        XCTAssertEqual(gif.width, 480)
        XCTAssertEqual(gif.height, 384)
    }

    func testGiphyListResponseToGifPageComputesHasMore() {
        let images = ImagesDTO(fixedWidthSmall: nil, fixedWidth: nil, fixedWidthDownsampled: nil, original: nil)
        let response = GiphyListResponse(
            data: [GifDTO(id: "1", title: "A", images: images)],
            pagination: PaginationDTO(totalCount: 50, count: 1, offset: 0)
        )

        let page = response.toGifPage()

        XCTAssertEqual(page.gifs.count, 1)
        XCTAssertTrue(page.hasMore)
    }

    func testGiphyListResponseToGifPageLastPageHasNoMore() {
        let images = ImagesDTO(fixedWidthSmall: nil, fixedWidth: nil, fixedWidthDownsampled: nil, original: nil)
        let response = GiphyListResponse(
            data: [GifDTO(id: "1", title: "A", images: images)],
            pagination: PaginationDTO(totalCount: 1, count: 1, offset: 0)
        )

        XCTAssertFalse(response.toGifPage().hasMore)
    }

    func testGiphyListResponseWithoutPaginationHasNoMore() {
        let response = GiphyListResponse(data: [], pagination: nil)
        XCTAssertFalse(response.toGifPage().hasMore)
    }
}
