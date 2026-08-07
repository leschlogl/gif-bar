import Models
import SwiftUI
import XCTest
@testable import Views

@MainActor
final class GIFCardSnapshotTests: XCTestCase {
    private let gif = Gif(id: "1", title: "Dancing Cat", width: 200, height: 180)

    private func makeCard(isFavorited: Bool, isSelected: Bool) -> GIFCard {
        GIFCard(
            gif: gif,
            cardHeight: 180,
            isFavorited: isFavorited,
            isSelected: isSelected,
            onToggleFavorite: {},
            onSelect: {},
            onCopyGif: {},
            onCopyURL: {},
            loadPreviewData: { _ in Data() }
        )
    }

    func testUnselectedUnfavorited() {
        assertViewSnapshot(makeCard(isFavorited: false, isSelected: false), size: CGSize(width: 180, height: 180))
    }

    func testFavorited() {
        assertViewSnapshot(makeCard(isFavorited: true, isSelected: false), size: CGSize(width: 180, height: 180))
    }

    func testSelectedShowsActionTray() {
        assertViewSnapshot(makeCard(isFavorited: false, isSelected: true), size: CGSize(width: 180, height: 180))
    }
}
