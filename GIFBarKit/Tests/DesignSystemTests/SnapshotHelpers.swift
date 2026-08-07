import AppKit
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
func assertViewSnapshot<V: View>(
    _ view: V,
    size: CGSize,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(origin: .zero, size: size)
    assertSnapshot(
        of: hostingView as NSView,
        // Font hinting/antialiasing differs subtly between a display-attached Mac (where
        // these were recorded) and a headless CI runner even on matching macOS/Xcode
        // versions, so exact pixel equality (the .image default) isn't achievable across
        // machines — tolerate a small amount of per-pixel and whole-image drift instead.
        as: .image(precision: 0.98, perceptualPrecision: 0.98, size: size),
        file: file,
        testName: testName,
        line: line
    )
}
