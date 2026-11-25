import SwiftUI

/// Haptic vocabulary: each event has exactly one feel, used everywhere.
/// Use with `.sensoryFeedback(Haptics.select, trigger: …)`.
enum Haptics {
    /// Picking something: a chip, a day count, a phase.
    static let select = SensoryFeedback.selection
    /// A light confirmation on a button.
    static let tap = SensoryFeedback.impact(weight: .light)
    /// A set done: firm, like racking the weight.
    static let setDone = SensoryFeedback.impact(weight: .medium)
    /// Rest is over, back to work.
    static let restOver = SensoryFeedback.warning
    /// A workout finished.
    static let workoutDone = SensoryFeedback.success
}
