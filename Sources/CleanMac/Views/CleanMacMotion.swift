import SwiftUI

enum CleanMacMotion {
    static let quick = Animation.easeInOut(duration: 0.18)
    static let page = Animation.easeOut(duration: 0.25)
    static let settle = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let pulse = Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
    static let float = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    static let beam = Animation.linear(duration: 1.4).repeatForever(autoreverses: false)

    static func allowed(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

private struct CleanMacPageTransitionModifier: ViewModifier {
    var offsetY: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offsetY)
    }
}

extension AnyTransition {
    static var cleanMacPage: AnyTransition {
        .modifier(
            active: CleanMacPageTransitionModifier(offsetY: 12, opacity: 0),
            identity: CleanMacPageTransitionModifier(offsetY: 0, opacity: 1)
        )
    }

    static var cleanMacInsert: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}
