import SwiftUI

/// Everything tappable squishes a little under the finger.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// Full-width capsule for the main action of a screen.
struct CapsuleButtonStyle: ButtonStyle {
    enum Kind {
        case accent
        case subtle
    }

    var kind: Kind = .accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(kind == .accent ? Color.white : Palette.text)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                if kind == .accent {
                    Capsule().fill(Palette.accentGradient)
                } else {
                    Capsule().fill(Palette.raised)
                }
            }
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    static func capsule(_ kind: CapsuleButtonStyle.Kind = .accent) -> CapsuleButtonStyle {
        CapsuleButtonStyle(kind: kind)
    }
}
