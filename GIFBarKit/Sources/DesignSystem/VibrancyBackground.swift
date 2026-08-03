import AppKit
import SwiftUI

/// Wraps `NSVisualEffectView` since SwiftUI's built-in materials can't hit the
/// exact dark, fairly opaque vibrancy the design calls for. `.active` (not
/// `.followsWindowActiveState`) keeps the vibrancy from looking flat, since a
/// `MenuBarExtra(.window)` panel isn't always the key window.
public struct VibrancyBackground: NSViewRepresentable {
    private let material: NSVisualEffectView.Material

    public init(material: NSVisualEffectView.Material = .hudWindow) {
        self.material = material
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.state = .active
        view.blendingMode = .behindWindow
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
