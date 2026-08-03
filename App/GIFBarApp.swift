import Persistence
import Services
import SwiftUI
import ViewModels
import Views

@main
struct GIFBarApp: App {
    @State private var viewModel: GifBarViewModel

    init() {
        let provider = MockGifProvider()
        let favorites = FavoritesService(store: UserDefaultsFavoritesStore())
        let clipboard = ClipboardService(provider: provider)
        _viewModel = State(initialValue: GifBarViewModel(provider: provider, clipboard: clipboard, favorites: favorites))
    }

    var body: some Scene {
        MenuBarExtra("GIFBar", systemImage: "photo.on.rectangle.angled") {
            RootView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
