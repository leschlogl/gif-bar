import DesignSystem
import SwiftUI

/// Toggles between the Trending and Favorites tabs — replaces the old text-tab-bar with
/// a single heart button, matching the updated toolbar design.
struct FavoritesToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? "heart.fill" : "heart")
                .font(.system(size: 14))
                .foregroundStyle(isActive ? .white : DesignTokens.Color.favoriteInactive)
                .frame(width: DesignTokens.Layout.toolbarIconButtonSize, height: DesignTokens.Layout.toolbarIconButtonSize)
                .background(
                    Circle().fill(isActive ? DesignTokens.Color.accent : DesignTokens.Color.searchButtonFill)
                )
        }
        .buttonStyle(.plain)
        .opacity(isHovering ? 0.85 : 1)
        .onHover { isHovering = $0 }
        .accessibilityLabel(isActive ? "Showing Favorites" : "Show Favorites")
        .accessibilityIdentifier("favoritesToggleButton")
    }
}
