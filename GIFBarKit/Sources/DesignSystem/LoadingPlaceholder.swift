import SwiftUI

public struct LoadingPlaceholder: View {
    private let height: CGFloat
    @State private var animating = false

    public init(height: CGFloat) {
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Color.shimmerBase)
                .overlay(
                    LinearGradient(
                        colors: [.clear, DesignTokens.Color.shimmerHighlight, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .offset(x: animating ? proxy.size.width : -proxy.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
                )
        }
        .frame(height: height)
        .onAppear {
            withAnimation(DesignTokens.Animations.shimmer) {
                animating = true
            }
        }
    }
}
