import DesignSystem
import SwiftUI
import ViewModels

struct TabBar: View {
    let selected: GifBarViewModel.Tab
    let onSelect: (GifBarViewModel.Tab) -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.tabGap) {
            tabButton(title: "Trending", tab: .trending)
            tabButton(title: "Favorites", tab: .favorites)
        }
    }

    private func tabButton(title: String, tab: GifBarViewModel.Tab) -> some View {
        let isSelected = selected == tab
        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(DesignTokens.Font.tabLabel)
                    .foregroundStyle(isSelected ? DesignTokens.Color.textPrimary : DesignTokens.Color.tabInactive)
                Rectangle()
                    .fill(isSelected ? DesignTokens.Color.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
