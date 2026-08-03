import SwiftUI

extension DesignTokens {
    public enum AnimationDuration {
        public static let hover: Double = 0.15
        public static let hoverScale: CGFloat = 1.03
        public static let traySlide: Double = 0.2
        public static let copyFlash: Double = 0.9
        public static let toastDismissDelay: Double = 1.4
        public static let shimmerLoop: Double = 1.3
    }

    public enum Animations {
        public static let hover = SwiftUI.Animation.easeInOut(duration: AnimationDuration.hover)
        public static let traySlide = SwiftUI.Animation.easeInOut(duration: AnimationDuration.traySlide)
        public static let copyFlash = SwiftUI.Animation.timingCurve(
            0.22, 0.61, 0.36, 1,
            duration: AnimationDuration.copyFlash
        )
        public static let shimmer = SwiftUI.Animation
            .linear(duration: AnimationDuration.shimmerLoop)
            .repeatForever(autoreverses: false)
    }
}
