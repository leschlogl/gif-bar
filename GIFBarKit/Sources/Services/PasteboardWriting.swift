import AppKit

/// Abstracts `NSPasteboard.general` so clipboard-writing code is unit-testable
/// without a live GUI pasteboard session. Method signatures mirror `NSPasteboard`'s
/// own exactly, so `NSPasteboard` already satisfies this protocol with no extra code.
public protocol PasteboardWriting: Sendable {
    @discardableResult func clearContents() -> Int
    @discardableResult func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
    @discardableResult func setData(_ data: Data?, forType dataType: NSPasteboard.PasteboardType) -> Bool
}

extension NSPasteboard: @retroactive @unchecked Sendable, PasteboardWriting {}
