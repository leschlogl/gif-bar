import SwiftUI

extension Color {
    fileprivate init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension DesignTokens {
    public enum Color {
        public static let accent = SwiftUI.Color(hex: 0x30D158)
        public static let accentHover = SwiftUI.Color(hex: 0x43E26B)
        public static let favorite = SwiftUI.Color(hex: 0xFF375F)

        public static let textPrimary = SwiftUI.Color(hex: 0xF5F5F7)
        public static let textSecondary = SwiftUI.Color(hex: 0x98989D)
        public static let textTertiary = SwiftUI.Color(hex: 0x636366)
        public static let tabInactive = SwiftUI.Color(hex: 0x8E8E93)

        public static let cardPlaceholderA = SwiftUI.Color(hex: 0x3A3A3C)
        public static let cardPlaceholderB = SwiftUI.Color(hex: 0x333335)
        public static let shimmerBase = SwiftUI.Color(hex: 0x2C2C2E)
        public static let shimmerHighlight = SwiftUI.Color(hex: 0x3A3A3C)

        public static let popoverTint = SwiftUI.Color(hex: 0x1C1C1E).opacity(0.88)
        public static let toastBackground = SwiftUI.Color(hex: 0x1C1C1E).opacity(0.92)

        public static let toolbarBorder = SwiftUI.Color.white.opacity(0.1)
        public static let searchButtonFill = SwiftUI.Color.white.opacity(0.10)
        public static let searchButtonFillHover = SwiftUI.Color.white.opacity(0.16)
        public static let searchFieldFill = SwiftUI.Color.white.opacity(0.08)

        public static let copyPillFill = SwiftUI.Color.white.opacity(0.16)
        public static let copyPillFillHover = SwiftUI.Color.white.opacity(0.26)

        public static let favoriteBadgeFill = SwiftUI.Color.black.opacity(0.45)
        public static let favoriteBadgeRing = SwiftUI.Color.white.opacity(0.14)
        public static let favoriteInactive = SwiftUI.Color.white.opacity(0.7)

        public static let copyFlashOverlay = SwiftUI.Color.white
    }
}
