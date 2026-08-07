import XCTest
@testable import Networking

final class GifDTOTests: XCTestCase {
    private func decode<T: Decodable>(_ json: String, as type: T.Type = T.self) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(json.utf8))
    }

    func testDecodesGifWithStringWidthAndHeight() throws {
        let json = """
        {
            "id": "abc123",
            "title": "Excited Cat",
            "images": {
                "fixed_width_small": { "url": "https://media.giphy.com/small.gif", "width": "100", "height": "75" },
                "fixed_width": { "url": "https://media.giphy.com/medium.gif", "width": "200", "height": "150" },
                "fixed_width_downsampled": { "url": "https://media.giphy.com/downsampled.gif", "width": "200", "height": "150" },
                "original": { "url": "https://media.giphy.com/original.gif", "width": "480", "height": "360" }
            }
        }
        """
        let dto = try decode(json, as: GifDTO.self)

        XCTAssertEqual(dto.id, "abc123")
        XCTAssertEqual(dto.title, "Excited Cat")
        XCTAssertEqual(dto.images.fixedWidthSmall?.width, 100)
        XCTAssertEqual(dto.images.fixedWidth?.height, 150)
        XCTAssertEqual(dto.images.original?.url, URL(string: "https://media.giphy.com/original.gif"))
    }

    func testDecodesAltText() throws {
        let json = """
        {
            "id": "abc123",
            "title": "Excited Cat",
            "alt_text": "A cat jumping in excitement",
            "images": {
                "original": { "url": "https://media.giphy.com/original.gif", "width": "480", "height": "360" }
            }
        }
        """
        let dto = try decode(json, as: GifDTO.self)

        XCTAssertEqual(dto.altText, "A cat jumping in excitement")
    }

    func testDecodesMissingAltTextAsNil() throws {
        let json = """
        {
            "id": "abc123",
            "title": "Excited Cat",
            "images": {
                "original": { "url": "https://media.giphy.com/original.gif", "width": "480", "height": "360" }
            }
        }
        """
        let dto = try decode(json, as: GifDTO.self)

        XCTAssertNil(dto.altText)
    }

    func testDecodesGifWithNumericWidthAndHeight() throws {
        let json = """
        {
            "id": "1",
            "title": "Numeric",
            "images": {
                "original": { "url": "https://media.giphy.com/original.gif", "width": 480, "height": 360 }
            }
        }
        """
        let dto = try decode(json, as: GifDTO.self)

        XCTAssertEqual(dto.images.original?.width, 480)
        XCTAssertEqual(dto.images.original?.height, 360)
    }

    func testDecodesGifWithMissingRenditions() throws {
        let json = """
        {
            "id": "1",
            "title": "Sparse",
            "images": {
                "original": { "url": "https://media.giphy.com/original.gif", "width": "480", "height": "360" }
            }
        }
        """
        let dto = try decode(json, as: GifDTO.self)

        XCTAssertNil(dto.images.fixedWidthSmall)
        XCTAssertNil(dto.images.fixedWidth)
        XCTAssertNotNil(dto.images.original)
    }

    func testDecodesListResponseWithPagination() throws {
        let json = """
        {
            "data": [
                {
                    "id": "1",
                    "title": "First",
                    "images": {
                        "fixed_width": { "url": "https://media.giphy.com/1.gif", "width": "200", "height": "150" },
                        "original": { "url": "https://media.giphy.com/1-original.gif", "width": "480", "height": "360" }
                    }
                }
            ],
            "pagination": { "total_count": 50, "count": 1, "offset": 0 }
        }
        """
        let response = try decode(json, as: GiphyListResponse.self)

        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.pagination?.totalCount, 50)
    }

    func testDecodesListResponseWithoutPagination() throws {
        let json = """
        { "data": [] }
        """
        let response = try decode(json, as: GiphyListResponse.self)

        XCTAssertTrue(response.data.isEmpty)
        XCTAssertNil(response.pagination)
    }

    func testDecodingThrowsForNonIntegerWidthString() {
        let json = """
        { "url": "https://media.giphy.com/1.gif", "width": "not-a-number", "height": "150" }
        """
        XCTAssertThrowsError(try decode(json, as: RenditionDTO.self))
    }
}
