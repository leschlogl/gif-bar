import SwiftUI

public struct PillButtonStyle: ButtonStyle {
    public enum Variant {
        case neutral
        case accent
    }

    private let variant: Variant

    public init(variant: Variant) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        PillLabel(configuration: configuration, variant: variant)
    }

    private struct PillLabel: View {
        let configuration: ButtonStyleConfiguration
        let variant: Variant
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .font(DesignTokens.Font.pillLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Layout.copyPillHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.pill)
                        .fill(fillColor)
                )
                .onHover { isHovering = $0 }
        }

        private var fillColor: Color {
            let hovering = isHovering || configuration.isPressed
            switch variant {
            case .neutral:
                return hovering ? DesignTokens.Color.copyPillFillHover : DesignTokens.Color.copyPillFill
            case .accent:
                return hovering ? DesignTokens.Color.accentHover : DesignTokens.Color.accent
            }
        }
    }
}
