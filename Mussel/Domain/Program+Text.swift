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

    func phaseWeeksText(_ index: Int) -> String {
        let weeks = weeks(ofPhase: index)
        return String(localized: "Weeks \(weeks.lowerBound)–\(weeks.upperBound)")
    }

    /// What's special about a phase, from the coach doc.
    static func phaseNote(_ index: Int) -> String? {
        switch index {
        case 0: String(localized: "Week 1 is two sets of everything, while you learn the moves.")
        case 2: String(localized: "The first two barbell workouts use an empty bar: technique only.")
        default: nil
        }
    }

    func restNote(phase: Int) -> String {
        String(localized: "Rest \(rest[phase]) s between sets")
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

extension ProgramNote {
    var symbol: String {
        switch self {
        case .focus: "scope"
        case .goal(.stronger): "dumbbell.fill"
        case .goal: "sparkles"
        case .quickStart: "hare"
        case .gentleStart: "tortoise"
        case .noBarbell: "shield.lefthalf.filled"
        case .shorterSessions, .longerSessions: "clock"
        case .swapped: "arrow.triangle.swap"
        }
    }

    var text: String {
        switch self {
        case .focus(.glutesLegs): String(localized: "Focus on glutes and legs: glute work instead of arm moves, and a little less pressing.")
        case .focus(.upper): String(localized: "Focus on the upper body: more sets for chest and back, and a chest or arm move instead of a second leg move.")
        case .focus(.balanced): String(localized: "Everything evenly, as the coaches wrote it.")
        case .goal(.stronger): String(localized: "Goal: strength. From the dumbbell phase, 6–10 reps and longer rests on the big moves.")
        case .goal(.shape): String(localized: "Goal: shape. 12–15 reps on the smaller moves and shorter rests.")
        case .goal(.confidence): String(localized: "Goal: feel at home in the gym.")
        case .quickStart: String(localized: "You've trained before, so the machines phase is 2 weeks.")
        case .gentleStart: String(localized: "The machines phase is 6 weeks, to get comfortable without rushing.")
        case .noBarbell(minor: true): String(localized: "Under 16: no barbell, and train with a coach nearby.")
        case .noBarbell(minor: false): String(localized: "Dumbbells instead of the barbell: easier on the joints.")
        case .shorterSessions: String(localized: "45 minutes: 5 exercises per workout.")
        case .longerSessions: String(localized: "75 minutes: one more exercise per workout.")
        case let .swapped(count): String(localized: "\(count) exercises swapped: not in your gym or switched off.")
        }
    }
}
