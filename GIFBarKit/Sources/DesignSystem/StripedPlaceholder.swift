import SwiftUI

/// Diagonal-stripe placeholder standing in for a thumbnail before real GIF art
/// loads. Colors are exact design tokens; stripe angle/spacing are eyeballed
/// (not specified in the design handoff).
public struct StripedPlaceholder: View {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = DesignTokens.Radius.card) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DesignTokens.Color.cardPlaceholderA))

            let stripeWidth: CGFloat = 14
            let period: CGFloat = 28
            var x = -size.height
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(DesignTokens.Color.cardPlaceholderB))
                x += period
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
