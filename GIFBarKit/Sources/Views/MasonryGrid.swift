import DesignSystem
import SwiftUI

/// Two independently-scrolling-height columns side by side — `LazyVGrid` forces
/// row-aligned cell heights across columns and can't produce true variable-height
/// masonry, so this composes `LazyVStack`s manually instead.
///
/// Takes an explicit `availableWidth` rather than measuring via `GeometryReader`:
/// the popover has a fixed, non-resizable size, and a `GeometryReader` inside a
/// `ScrollView` has no natural height to report, which is a well-known way to end
/// up with a zero-height masonry.
public struct MasonryGrid<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let availableWidth: CGFloat
    private let columns: Int
    private let spacing: CGFloat
    private let cardHeight: (Item, CGFloat) -> CGFloat
    private let content: (Item, CGFloat, CGFloat) -> Content

    public init(
        items: [Item],
        availableWidth: CGFloat,
        columns: Int = DesignTokens.Layout.gridColumns,
        spacing: CGFloat = DesignTokens.Spacing.gridGutter,
        cardHeight: @escaping (Item, CGFloat) -> CGFloat,
        @ViewBuilder content: @escaping (_ item: Item, _ cardWidth: CGFloat, _ cardHeight: CGFloat) -> Content
    ) {
        self.items = items
        self.availableWidth = availableWidth
        self.columns = columns
        self.spacing = spacing
        self.cardHeight = cardHeight
        self.content = content
    }

    public var body: some View {
        let cardWidth = max(0, (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        let balanced = MasonryBalancer.distribute(items, columns: columns) { cardHeight($0, cardWidth) }

        HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(balanced.enumerated()), id: \.offset) { _, column in
                LazyVStack(spacing: DesignTokens.Spacing.cardMarginBottom) {
                    ForEach(column) { item in
                        content(item, cardWidth, cardHeight(item, cardWidth))
                            .frame(width: cardWidth)
                    }
                }
            }
        }
    }
}
