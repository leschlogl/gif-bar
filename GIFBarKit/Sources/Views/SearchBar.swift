import DesignSystem
import SwiftUI

/// The toolbar's search row — kept in `Views` rather than `DesignSystem` since
/// it's coupled to this screen's specific toolbar behavior, not a generic
/// reusable primitive.
struct SearchBar: View {
    @Binding var query: String
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField("Search GIFs", text: $query)
                .textFieldStyle(.plain)
                .font(DesignTokens.Font.searchField)
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: DesignTokens.Layout.searchFieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.searchField)
                        .fill(DesignTokens.Color.searchFieldFill)
                )
                .focused($isFocused)
                .accessibilityLabel("Search GIFs")

            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .font(DesignTokens.Font.tabLabel)
                .foregroundStyle(DesignTokens.Color.accent)
        }
        .padding(.horizontal, DesignTokens.Spacing.contentPaddingSides)
        .frame(height: DesignTokens.Layout.toolbarHeight)
        .onAppear { isFocused = true }
    }
}
