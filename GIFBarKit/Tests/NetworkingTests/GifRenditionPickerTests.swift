import XCTest
@testable import Networking

final class GifRenditionPickerTests: XCTestCase {
    private let small = RenditionDTO(url: URL(string: "https://example.com/small.gif")!, width: 100, height: 75)
    private let medium = RenditionDTO(url: URL(string: "https://example.com/medium.gif")!, width: 200, height: 150)
    private let downsampled = RenditionDTO(url: URL(string: "https://example.com/downsampled.gif")!, width: 200, height: 150)
    private let original = RenditionDTO(url: URL(string: "https://example.com/original.gif")!, width: 480, height: 360)

    private func images(
        small: RenditionDTO? = nil,
        medium: RenditionDTO? = nil,
        downsampled: RenditionDTO? = nil,
        original: RenditionDTO? = nil
    ) -> ImagesDTO {
        ImagesDTO(fixedWidthSmall: small, fixedWidth: medium, fixedWidthDownsampled: downsampled, original: original)
    }

    func testPicksSmallBelowThreshold() {
        let all = images(small: small, medium: medium, downsampled: downsampled, original: original)
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 50, scale: 1)
        XCTAssertEqual(result, small)
    }

    func testPicksSmallExactlyAtThreshold() {
        let all = images(small: small, medium: medium, downsampled: downsampled, original: original)
        // 55pt * 2x scale = 110px, exactly at the small/medium boundary.
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 55, scale: 2)
        XCTAssertEqual(result, small)
    }

    func testPicksMediumJustAboveSmallThreshold() {
        let all = images(small: small, medium: medium, downsampled: downsampled, original: original)
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 56, scale: 2)
        XCTAssertEqual(result, medium)
    }

    func testPicksMediumAtUpperThreshold() {
        let all = images(small: small, medium: medium, downsampled: downsampled, original: original)
        // 110pt * 2x scale = 220px, at the medium/large boundary — still fixed_width.
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 110, scale: 2)
        XCTAssertEqual(result, medium)
    }

    func testCapsAtMediumWellAboveThreshold() {
        let all = images(small: small, medium: medium, downsampled: downsampled, original: original)
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 1000, scale: 3)
        XCTAssertEqual(result, medium, "must never fall through to `original`, even far above the threshold")
    }

    func testFallsBackWhenPreferredRenditionMissing() {
        let all = images(medium: nil, downsampled: downsampled, original: original)
        let result = GifRenditionPicker.rendition(for: all, targetWidth: 50, scale: 1)
        XCTAssertEqual(result, downsampled, "should fall back to another rendition when the ideal one is absent")
    }

    func testReturnsNilWhenNoRenditionsAvailable() {
        let empty = images()
        XCTAssertNil(GifRenditionPicker.rendition(for: empty, targetWidth: 50, scale: 1))
    }
}
