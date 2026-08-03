import DesignSystem
import SwiftUI
import ViewModels

struct ToastOverlay: View {
    let viewModel: GifBarViewModel

    var body: some View {
        if let toast = viewModel.toast {
            ToastView(text: text(for: toast.kind))
                .padding(.bottom, 20)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.18), value: viewModel.toast)
        }
    }

    private func text(for kind: ToastMessage.Kind) -> String {
        switch kind {
        case .gifCopied: return "GIF Copied"
        case .linkCopied: return "Link Copied"
        case .addedToFavorites: return "Added to Favorites"
        case .removedFromFavorites: return "Removed from Favorites"
        }
    }
}
