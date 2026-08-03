import SwiftUI

public struct RootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36))
            Text("GIFBar")
                .font(.headline)
        }
        .frame(minWidth: 500, minHeight: 700)
    }
}
