import Foundation

extension Prescription {
    /// "3 × 10–12", "2 × 20–30 s", "2 × 8–10 per side".
    var summary: String {
        let range = target.lowerBound == target.upperBound
            ? "\(target.lowerBound)"
            : "\(target.lowerBound)–\(target.upperBound)"
        switch (unit, perSide) {
        case (.seconds, _): return String(localized: "\(sets) × \(range) s")
        case (.reps, true): return String(localized: "\(sets) × \(range) per side")
        case (.reps, false): return "\(sets) × \(range)"
        }
    }
}

extension Program {
    /// How the training days fall in a week.
    var weekPlan: String {
        switch daysPerWeek {
        case 2: String(localized: "Workouts A and B once a week each, at least two days apart.")
        case 4: String(localized: "Upper and lower body on separate days: Monday, Tuesday, Thursday and Friday.")
        default: String(localized: "Full body three times a week. A and B take turns: A, B, A one week and B, A, B the next.")
        }
    }

    static func phaseWeeks(_ index: Int) -> String {
        String(localized: "Weeks \(index * 4 + 1)–\(index * 4 + 4)")
    }

    /// What's special about a phase, from the coach doc.
    static func phaseNote(_ index: Int) -> String? {
        switch index {
        case 0: String(localized: "Week 1 is two sets of everything, while you learn the moves.")
        case 2: String(localized: "The first two barbell workouts use an empty bar: technique only.")
        default: nil
        }
    }

    static func restNote(phase: Int) -> String {
        String(localized: "Rest \(restSeconds(phase: phase)) s between sets")
    }
}

extension WorkoutTemplate {
    var totalSets: Int { items.reduce(0) { $0 + $1.sets } }
}

extension Exercise {
    /// The muscles, joined for a caption: "Quads · Glutes".
    var muscleLine: String {
        muscles.map(\.name).joined(separator: " · ")
    }
}
