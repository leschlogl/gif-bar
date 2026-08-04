import AppKit
import DesignSystem
import SwiftUI
import ViewModels

/// The toolbar's "•••" overflow menu. Deliberately **not** a SwiftUI `Menu` — on macOS,
/// `Menu` doesn't reliably respect a custom label's background/hover styling (it kept
/// rendering without the circular fill or hover tint `ToolbarButton`/
/// `FavoritesToggleButton` get for free), so the trigger is a plain `Button` — the exact
/// same mechanism those two already use successfully — and the dropdown is a real
/// `NSMenu` shown programmatically, anchored to a captured `NSView`.
struct SettingsMenu: View {
    let viewModel: GifBarViewModel

    @State private var anchorView: NSView?
    @State private var isHovering = false

    var body: some View {
        Button(action: showMenu) {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .frame(width: DesignTokens.Layout.toolbarIconButtonSize, height: DesignTokens.Layout.toolbarIconButtonSize)
                .background(
                    Circle().fill(isHovering ? DesignTokens.Color.searchButtonFillHover : DesignTokens.Color.searchButtonFill)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .background(ViewAnchor(view: $anchorView))
        .accessibilityLabel("More")
    }

    private func showMenu() {
        guard let anchorView else { return }

        let menu = NSMenu()
        menu.addItem(ClosureMenuItem(title: "Launch at Login", isOn: viewModel.isLaunchAtLoginEnabled) {
            viewModel.toggleLaunchAtLogin()
        })
        menu.addItem(ClosureMenuItem(title: "About GIFs") {
            viewModel.showAboutPanel()
        })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Quit GIFs") {
            viewModel.quitApp()
        })

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: anchorView.bounds.height + 4), in: anchorView)
    }
}

/// Captures the underlying `NSView` at this point in the view tree, purely so
/// `SettingsMenu` can anchor an `NSMenu` popup to it — renders nothing itself.
private struct ViewAnchor: NSViewRepresentable {
    @Binding var view: NSView?

    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async { view = nsView }
        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// An `NSMenuItem` that runs a closure instead of requiring a target/selector pair.
private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, isOn: Bool = false, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(invoke), keyEquivalent: "")
        target = self
        state = isOn ? .on : .off
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func invoke() {
        handler()
    }
}
