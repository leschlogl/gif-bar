import DesignSystem
import Models
import SwiftUI

public struct GIFCard: View {
    private let gif: Gif
    private let cardHeight: CGFloat
    private let isFavorited: Bool
    private let isSelected: Bool
    private let onToggleFavorite: () -> Void
    private let onSelect: () -> Void
    private let onCopyGif: () -> Void
    private let onCopyURL: () -> Void
    private let loadPreviewData: (URL) async throws -> Data

    @State private var isHovering = false
    @FocusState private var isFocused: Bool

    public init(
        gif: Gif,
        cardHeight: CGFloat,
        isFavorited: Bool,
        isSelected: Bool,
        onToggleFavorite: @escaping () -> Void,
        onSelect: @escaping () -> Void,
        onCopyGif: @escaping () -> Void,
        onCopyURL: @escaping () -> Void,
        loadPreviewData: @escaping (URL) async throws -> Data
    ) {
        self.gif = gif
        self.cardHeight = cardHeight
        self.isFavorited = isFavorited
        self.isSelected = isSelected
        self.onToggleFavorite = onToggleFavorite
        self.onSelect = onSelect
        self.onCopyGif = onCopyGif
        self.onCopyURL = onCopyURL
        self.loadPreviewData = loadPreviewData
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            selectableBody
            favoriteButton
                .padding(DesignTokens.Spacing.favoriteBadgeInset)
        }
        .frame(height: cardHeight)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(.return) { onSelect(); return .handled }
        .onKeyPress(.space) { onSelect(); return .handled }
        .onHover { isHovering = $0 }
        // Giphy's alt_text is purpose-written for screen readers and often more
        // descriptive than title (which can be terse or auto-generated) — prefer it,
        // falling back to title for mock data / GIFs Giphy didn't supply one for.
        .accessibilityLabel(gif.altText ?? "\(gif.title) GIF")
        .accessibilityIdentifier("gifCard")
        .contextMenu {
            Button("Copy GIF URL", action: onCopyURL)
            Button("Copy GIF", action: onCopyGif)
            Divider()
            Button(isFavorited ? "Remove Favorite" : "Add Favorite", action: onToggleFavorite)
        }
    }

    private var selectableBody: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottom) {
                if let previewURL = gif.previewURL {
                    AnimatedGIFView(url: previewURL, loadData: loadPreviewData)
                } else {
                    StripedPlaceholder(cornerRadius: DesignTokens.Radius.card)
                }

                if isSelected {
                    LinearGradient(
                        colors: [.clear, DesignTokens.Color.selectionScrim],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: DesignTokens.Layout.masonryScrimHeight)

                    actionTray
                        .padding(.horizontal, DesignTokens.Spacing.pillInset)
                        .padding(.bottom, DesignTokens.Spacing.pillInset)
                }

            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
        }
        .buttonStyle(.plain)
        .animation(DesignTokens.Animations.traySlide, value: isSelected)
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.system(size: DesignTokens.Layout.favoriteIconSize))
                .foregroundStyle(isFavorited ? DesignTokens.Color.favorite : DesignTokens.Color.favoriteInactive)
                .frame(width: DesignTokens.Layout.favoriteBadgeSize, height: DesignTokens.Layout.favoriteBadgeSize)
                .background(
                    Circle()
                        .fill(DesignTokens.Color.favoriteBadgeFill)
                        .overlay(Circle().stroke(DesignTokens.Color.favoriteBadgeRing, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFavorited ? 1.08 : 1)
        .opacity(isFavorited || isHovering ? 1 : 0)
        .animation(DesignTokens.Animations.hover, value: isFavorited || isHovering)
        .accessibilityLabel(isFavorited ? "Remove from Favorites" : "Add to Favorites")
        .accessibilityIdentifier("favoriteButton")
    }

    private var actionTray: some View {
        HStack(spacing: DesignTokens.Spacing.pillGap) {
            Button("Copy GIF", action: onCopyGif)
                .buttonStyle(PillButtonStyle(variant: .neutral))
            Button("Copy URL", action: onCopyURL)
                .buttonStyle(PillButtonStyle(variant: .accent))
        }
    }
}
