import SwiftUI

public struct LoadingPlaceholder: View {
    private let height: CGFloat
    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(height: CGFloat) {
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Color.shimmerBase)
                .overlay {
                    // Reduce Motion turns this into a static highlight rather than skipping
                    // it outright — it's the only visual distinguishing a loading card from
                    // a plain placeholder, so removing it entirely would lose information,
                    // not just motion.
                    if reduceMotion {
                        LinearGradient(
                            colors: [.clear, DesignTokens.Color.shimmerHighlight, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
                    } else {
                        LinearGradient(
                            colors: [.clear, DesignTokens.Color.shimmerHighlight, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: animating ? proxy.size.width : -proxy.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
                    }
                }
        }
        .frame(height: height)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(DesignTokens.Animations.shimmer) {
                animating = true
            }
        }
    }
}
