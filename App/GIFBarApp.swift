import Networking
import Persistence
import Services
import SwiftUI
import ViewModels
import Views

@main
struct GIFBarApp: App {
    @State private var viewModel: GifBarViewModel

    init() {
        let apiClient = APIClient(apiKey: GiphyAPIKey.fromMainBundle() ?? "")
        let provider = GiphyService(apiClient: apiClient)
        let favorites = FavoritesService(store: UserDefaultsFavoritesStore())
        // Shared between `ClipboardService` and the grid's `AnimatedGIFView` (via
        // `GifBarViewModel.loadImageData`) so a GIF already rendered on screen reuses
        // cached bytes instead of re-downloading when copied.
        let imageCache = ImageCache()
        let clipboard = ClipboardService(provider: provider, imageLoader: imageCache)
        _viewModel = State(initialValue: GifBarViewModel(
            provider: provider,
            clipboard: clipboard,
            favorites: favorites,
            imageLoader: imageCache
        ))
    }

    var body: some Scene {
        MenuBarExtra("GIFBar", image: "MenuBarIcon") {
            RootView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
