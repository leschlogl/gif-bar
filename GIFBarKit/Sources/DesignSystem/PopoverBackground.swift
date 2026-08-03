import SwiftUI

public struct PopoverBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            VibrancyBackground(material: .hudWindow)
            DesignTokens.Color.popoverTint
        }
    }
}
