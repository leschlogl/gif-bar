import DesignSystem
import Models
import SwiftUI
import ViewModels

struct GifGridView: View {
    let viewModel: GifBarViewModel

    var body: some View {
        ScrollView {
            content
                .padding(.top, DesignTokens.Spacing.contentPaddingTop)
                .padding(.horizontal, DesignTokens.Spacing.contentPaddingSides)
                .padding(.bottom, DesignTokens.Spacing.contentPaddingBottom)
        }
        // Confirmed via runtime inspection that this already sets the underlying
        // NSScrollView's hasVerticalScroller to false — the scroll indicator still
        // visible on screen is drawn by SwiftUI's own internal compositor for
        // pure-SwiftUI scroll content on this macOS version, above any AppKit NSView or
        // SwiftUI overlay we can reach. Left as a known, deliberately-not-fixed
        // cosmetic issue rather than replacing ScrollView with a custom
        // NSScrollView/NSHostingView bridge for it.
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeletonGrid()
        } else if viewModel.isErrorState {
            ErrorStateView(retryAction: { viewModel.retryLoad() })
        } else if viewModel.isFavoritesEmpty {
            EmptyStateView(
                icon: "heart",
                iconSize: 36,
                title: "No Favorites Yet",
                subtitle: "Tap the heart on any GIF to save it here."
            )
        } else if viewModel.isSearchEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                iconSize: 28,
                title: "No GIFs Found",
                subtitle: "Try a different search term."
            )
        } else {
            VStack(spacing: 0) {
                MasonryGrid(
                    items: viewModel.gifs,
                    availableWidth: DesignTokens.Layout.contentWidth,
                    cardHeight: { gif, cardWidth in cardWidth * CGFloat(gif.height) / CGFloat(gif.width) }
                ) { gif, _, cardHeight in
                    GIFCard(
                        gif: gif,
                        cardHeight: cardHeight,
                        isFavorited: viewModel.favoriteIDs.contains(gif.id),
                        isSelected: viewModel.selectedGifID == gif.id,
                        onToggleFavorite: { Task { await viewModel.toggleFavorite(gif) } },
                        onSelect: { viewModel.selectCard(gif) },
                        onCopyGif: { Task { await viewModel.copyGif(gif) } },
                        onCopyURL: { Task { await viewModel.copyURL(gif) } },
                        loadPreviewData: { url in try await viewModel.loadImageData(for: url) }
                    )
                }

                // A footer sentinel, not a per-card check: it sits below both masonry
                // columns regardless of which one is taller, so it only appears once the
                // user has actually scrolled past all currently-loaded content — and
                // disappears for good once hasMore goes false, rather than needing to
                // identify which specific card is "the last" in a variable-height layout.
                if viewModel.hasMore {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.top, DesignTokens.Spacing.gridGutter)
                        .onAppear { viewModel.loadNextPageIfNeeded() }
                }
            }
        }
    }
}
