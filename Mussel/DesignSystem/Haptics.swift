import SwiftUI

/// Haptic vocabulary: each event has exactly one feel, used everywhere.
/// Use with `.sensoryFeedback(Haptics.select, trigger: …)`.
enum Haptics {
    /// Picking something: a chip, a day count, a phase.
    static let select = SensoryFeedback.selection
    /// A light confirmation on a button.
    static let tap = SensoryFeedback.impact(weight: .light)
}
