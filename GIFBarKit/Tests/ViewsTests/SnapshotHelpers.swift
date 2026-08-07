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
        as: .image(size: size),
        file: file,
        testName: testName,
        line: line
    )
}
