import DesignSystem
import SwiftUI

private struct SkeletonItem: Identifiable {
    let id: Int
    let height: CGFloat
}

private let skeletonHeights: [CGFloat] = [160, 200, 140, 220, 180, 150, 190, 170]

struct LoadingSkeletonGrid: View {
    private let items = skeletonHeights.enumerated().map { SkeletonItem(id: $0.offset, height: $0.element) }

    var body: some View {
        MasonryGrid(
            items: items,
            availableWidth: DesignTokens.Layout.contentWidth,
            cardHeight: { item, _ in item.height }
        ) { _, _, cardHeight in
            LoadingPlaceholder(height: cardHeight)
        }
    }
}
