import SwiftUI

public struct ToastView: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(DesignTokens.Font.toast)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(DesignTokens.Color.toastBackground))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
