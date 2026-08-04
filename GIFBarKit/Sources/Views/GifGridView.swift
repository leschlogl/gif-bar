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
                    .onAppear { viewModel.loadNextPageIfNeeded(currentItem: gif) }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.top, DesignTokens.Spacing.gridGutter)
                }
            }
        }
    }
}
