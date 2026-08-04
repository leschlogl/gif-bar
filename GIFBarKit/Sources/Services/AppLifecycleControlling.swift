import AppKit

/// Wraps the handful of `NSApplication` calls the settings menu needs. Protocol-wrapped
/// so it's fakeable in `ViewModels` tests — same pattern as `PasteboardWriting`.
public protocol AppLifecycleControlling: Sendable {
    func showAboutPanel()
    func terminate()
}

public struct NSApplicationLifecycleController: AppLifecycleControlling {
    public init() {}

    public func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    public func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
