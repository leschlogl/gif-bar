import SwiftUI
import Views

@main
struct GiphyBarApp: App {
    var body: some Scene {
        MenuBarExtra("GiphyBar", systemImage: "photo.on.rectangle.angled") {
            RootView()
        }
        .menuBarExtraStyle(.window)
    }
}
