import SwiftUI
import Views

@main
struct GIFBarApp: App {
    var body: some Scene {
        MenuBarExtra("GIFBar", systemImage: "photo.on.rectangle.angled") {
            RootView()
        }
        .menuBarExtraStyle(.window)
    }
}
