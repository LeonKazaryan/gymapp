import SwiftUI

/// Brand colors.
///
/// Mussel is a dark gym at night with one warm light: coral is for the muscles that work and
/// for everything you do (buttons, progress). Machines and chrome stay cool and quiet. Each
/// level of the program has its own color, so a phase, a badge and an exercise card agree.
enum Palette {
    static let ink = Color(rgb: 0x0B0D12)
    /// Cards on the ink.
    static let surface = Color(rgb: 0x151922)
    /// Controls and chips on a card.
    static let raised = Color(rgb: 0x1E232E)
    static let hairline = Color.white.opacity(0.07)

    static let text = Color(rgb: 0xF2F4F8)
    static let secondary = Color(rgb: 0x9AA3B5)
    static let tertiary = Color(rgb: 0x5E6678)

    /// The one warm color: primary actions and progress.
    static let accent = Color(rgb: 0xFF6A4D)
    static let accentLight = Color(rgb: 0xFFB27A)
    /// Working muscles in the demos.
    static let muscle = Color(rgb: 0xFF5B45)
    static let mint = Color(rgb: 0x5BE3A6)

    /// Machines, dumbbells, barbell: the three levels and the three phases.
    static let levels: [Color] = [Color(rgb: 0x6FB7FF), Color(rgb: 0xFFC15E), Color(rgb: 0xB58CFF)]

    static func level(_ level: Int) -> Color {
        levels[max(0, min(level - 1, levels.count - 1))]
    }

    static let accentGradient = LinearGradient(
        colors: [accent, accentLight], startPoint: .leading, endPoint: .trailing
    )
}

extension Color {
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
