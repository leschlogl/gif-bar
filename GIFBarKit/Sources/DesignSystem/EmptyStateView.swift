import SwiftUI

public struct EmptyStateView: View {
    private let icon: String
    private let iconSize: CGFloat
    private let title: String
    private let subtitle: String

    public init(icon: String, iconSize: CGFloat = 32, title: String, subtitle: String) {
        self.icon = icon
        self.iconSize = iconSize
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(DesignTokens.Color.textTertiary)
            Text(title)
                .font(DesignTokens.Font.emptyStateTitle)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Text(subtitle)
                .font(DesignTokens.Font.emptyStateSubtitle)
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 70)
        .frame(maxWidth: .infinity)
    }
}
