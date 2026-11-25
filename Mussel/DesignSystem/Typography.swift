import SwiftUI

/// Type scale. Everything is SF Pro Rounded and follows Dynamic Type.
enum Typography {
    /// A full screen's title.
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    static let title = Font.system(.title2, design: .rounded, weight: .bold)
    static let headline = Font.system(.headline, design: .rounded, weight: .bold)
    static let body = Font.system(.body, design: .rounded)
    static let label = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let caption = Font.system(.footnote, design: .rounded, weight: .medium)
    /// Small capitals over a section.
    static let eyebrow = Font.system(.caption, design: .rounded, weight: .bold)
    /// Sets × reps, numbers in lists.
    static let numbers = Font.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit()
}
