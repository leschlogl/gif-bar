import SwiftUI

public struct ErrorStateView: View {
    private let icon: String
    private let iconSize: CGFloat
    private let title: String
    private let subtitle: String
    private let retryAction: () -> Void

    public init(
        icon: String = "wifi.exclamationmark",
        iconSize: CGFloat = 32,
        title: String = "Something Went Wrong",
        subtitle: String = "Check your connection and try again.",
        retryAction: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.title = title
        self.subtitle = subtitle
        self.retryAction = retryAction
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
            Button("Try Again", action: retryAction)
                .buttonStyle(PillButtonStyle(variant: .accent))
                .fixedSize()
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 70)
        .frame(maxWidth: .infinity)
    }
}
