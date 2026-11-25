import SwiftUI

/// Animation tokens. Feature code uses these, never raw values.
enum Motion {
    /// Button press-in.
    static let press = Animation.spring(duration: 0.2, bounce: 0.2)
    /// Toggles, chips, small state changes.
    static let snappy = Animation.spring(duration: 0.3, bounce: 0.15)
    /// Cards appearing, screens changing.
    static let smooth = Animation.spring(duration: 0.5, bounce: 0)
    /// Delay between items of a cascade.
    static let stagger = 0.05
}
