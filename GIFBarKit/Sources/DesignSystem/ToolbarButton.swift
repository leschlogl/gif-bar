import SwiftUI

public struct ToolbarButton: View {
    private let systemImage: String
    private let accessibilityLabel: String
    private let action: () -> Void
    @State private var isHovering = false

    public init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .frame(width: DesignTokens.Layout.searchButtonSize, height: DesignTokens.Layout.searchButtonSize)
                .background(
                    Circle().fill(isHovering ? DesignTokens.Color.searchButtonFillHover : DesignTokens.Color.searchButtonFill)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(accessibilityLabel)
    }
}
