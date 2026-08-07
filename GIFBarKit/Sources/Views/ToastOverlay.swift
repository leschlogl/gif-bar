import DesignSystem
import SwiftUI
import ViewModels

struct ToastOverlay: View {
    let viewModel: GifBarViewModel

    var body: some View {
        Group {
            if let toast = viewModel.toast {
                ToastView(text: text(for: toast.kind))
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.toast)
        // A toast is a purely visual, self-dismissing overlay — without this, VoiceOver
        // users get no feedback at all that a copy/favorite action succeeded, since
        // nothing moves focus to it and it's gone before a manual swipe-navigation
        // would find it.
        .onChange(of: viewModel.toast) { _, toast in
            guard let toast else { return }
            AccessibilityNotification.Announcement(text(for: toast.kind)).post()
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
