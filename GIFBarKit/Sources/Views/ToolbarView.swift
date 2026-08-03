import DesignSystem
import SwiftUI
import ViewModels

struct ToolbarView: View {
    @Bindable var viewModel: GifBarViewModel

    var body: some View {
        Group {
            if viewModel.isSearchFieldOpen {
                SearchBar(query: $viewModel.searchQuery, onCancel: { viewModel.closeSearch() })
            } else {
                defaultRow
            }
        }
        .frame(height: DesignTokens.Layout.toolbarHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.Color.toolbarBorder)
                .frame(height: 1)
        }
    }

    private var defaultRow: some View {
        HStack(spacing: DesignTokens.Spacing.tabGap) {
            Text("GIFs")
                .font(DesignTokens.Font.title)
                .foregroundStyle(DesignTokens.Color.textPrimary)

            TabBar(selected: viewModel.tab, onSelect: { viewModel.selectTab($0) })

            Spacer()

            ToolbarButton(systemImage: "magnifyingglass", accessibilityLabel: "Search") {
                viewModel.openSearch()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.contentPaddingSides)
    }
}
