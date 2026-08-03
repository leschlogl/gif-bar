import DesignSystem
import SwiftUI
import ViewModels

public struct RootView: View {
    private let viewModel: GifBarViewModel

    public init(viewModel: GifBarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            ToolbarView(viewModel: viewModel)
            GifGridView(viewModel: viewModel)
        }
        .frame(width: DesignTokens.Layout.popoverSize.width, height: DesignTokens.Layout.popoverSize.height)
        .background(PopoverBackground())
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.popover))
        .overlay(alignment: .bottom) {
            ToastOverlay(viewModel: viewModel)
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

#Preview {
    RootView(viewModel: .preview())
}
