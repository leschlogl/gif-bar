import CoreGraphics

extension DesignTokens {
    public enum Layout {
        public static let popoverSize = CGSize(width: 380, height: 580)
        public static let toolbarHeight: CGFloat = 52
        /// Popover width minus both side content-padding insets — the width
        /// available to the masonry grid's columns. The popover has a fixed,
        /// non-resizable size, so this can be computed once rather than
        /// measured at runtime with a `GeometryReader`.
        public static let contentWidth: CGFloat = popoverSize.width - 2 * Spacing.contentPaddingSides
        public static let searchFieldHeight: CGFloat = 34
        public static let searchButtonSize: CGFloat = 30
        public static let favoriteBadgeSize: CGFloat = 28
        public static let favoriteIconSize: CGFloat = 14
        public static let copyPillHeight: CGFloat = 30
        public static let gridColumns = 2
        public static let masonryScrimHeight: CGFloat = 70
        public static let focusRingWidth: CGFloat = 3
    }
}
