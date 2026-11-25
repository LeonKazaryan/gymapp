import SwiftUI

extension View {
    /// A card on the ink: slightly lighter, with a hairline edge.
    func card(cornerRadius: CGFloat = 24, fill: Color = Palette.surface) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
    }

    /// The stage a demo plays on: a soft light from above fading into the card.
    func demoStage(cornerRadius: CGFloat = 20) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color(rgb: 0x232A38), Color(rgb: 0x12151C)],
                        center: UnitPoint(x: 0.5, y: 0.25), startRadius: 0, endRadius: 260
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// The ink background behind a whole screen.
    func screenBackground() -> some View {
        background(Palette.ink.ignoresSafeArea())
    }
}

/// A small label with a colored dot: a level, a muscle, a phase.
struct Chip: View {
    let text: String
    var color: Color = Palette.secondary
    var filled = false

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(filled ? Palette.text : Palette.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(filled ? color.opacity(0.18) : Palette.raised, in: Capsule())
    }
}

/// Small capitals over a section.
struct Eyebrow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(Typography.eyebrow)
            .tracking(1.2)
            .foregroundStyle(Palette.tertiary)
    }
}
