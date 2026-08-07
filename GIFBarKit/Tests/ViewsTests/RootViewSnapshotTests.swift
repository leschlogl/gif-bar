import DesignSystem
import SwiftUI
import ViewModels
import XCTest
@testable import Views

@MainActor
final class RootViewSnapshotTests: XCTestCase {
    private func waitForDebounce() async throws {
        try await Task.sleep(for: .milliseconds(350))
    }

    private func waitForBackgroundTask() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    func testTrendingLoaded() async {
        let viewModel = GifBarViewModel.preview()
        await viewModel.onAppear()

        assertViewSnapshot(RootView(viewModel: viewModel), size: DesignTokens.Layout.popoverSize)
    }

    func testSearchNoResults() async throws {
        let viewModel = GifBarViewModel.preview()
        await viewModel.onAppear()
        viewModel.searchQuery = "zzznomatch"
        try await waitForDebounce()

        assertViewSnapshot(RootView(viewModel: viewModel), size: DesignTokens.Layout.popoverSize)
    }

    func testFavoritesEmpty() async throws {
        let viewModel = GifBarViewModel.preview()
        await viewModel.onAppear()
        viewModel.selectTab(.favorites)
        try await waitForBackgroundTask()

        assertViewSnapshot(RootView(viewModel: viewModel), size: DesignTokens.Layout.popoverSize)
    }
}
