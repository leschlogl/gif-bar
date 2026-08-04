import DesignSystem
import SwiftUI
import ViewModels

struct ToolbarView: View {
    @Bindable var viewModel: GifBarViewModel

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.toolbarItemGap) {
            TextField("Search GIFs", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(DesignTokens.Font.searchField)
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: DesignTokens.Layout.searchFieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.searchField)
                        .fill(DesignTokens.Color.searchFieldFill)
                )
                .accessibilityLabel("Search GIFs")

            FavoritesToggleButton(isActive: viewModel.tab == .favorites) {
                viewModel.selectTab(viewModel.tab == .favorites ? .trending : .favorites)
            }

            SettingsMenu(viewModel: viewModel)
        }
        .padding(.horizontal, DesignTokens.Spacing.contentPaddingSides)
        .frame(height: DesignTokens.Layout.toolbarHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.Color.toolbarBorder)
                .frame(height: 1)
        }
    }
}
