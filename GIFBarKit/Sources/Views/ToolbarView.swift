import DesignSystem
import SwiftUI
import ViewModels

struct ToolbarView: View {
    @Bindable var viewModel: GifBarViewModel

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.toolbarItemGap) {
            HStack(spacing: 4) {
                TextField("Search GIFs", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Font.searchField)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                    .accessibilityLabel("Search GIFs")
                    .accessibilityIdentifier("searchField")

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityIdentifier("clearSearchButton")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: DesignTokens.Layout.searchFieldHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.searchField)
                    .fill(DesignTokens.Color.searchFieldFill)
            )

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
