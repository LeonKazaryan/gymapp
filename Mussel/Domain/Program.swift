import Foundation

enum RepUnit: Sendable {
    case reps
    case seconds
}

/// One line of a workout: "Leg Press, 3 × 10–12".
struct Prescription: Hashable, Sendable {
    let exercise: ExerciseID
    let sets: Int
    let target: ClosedRange<Int>
    var unit: RepUnit = .reps
    var perSide = false

    static func reps(_ exercise: ExerciseID, _ sets: Int, _ target: ClosedRange<Int>, perSide: Bool = false) -> Prescription {
        Prescription(exercise: exercise, sets: sets, target: target, perSide: perSide)
    }

    static func hold(_ exercise: ExerciseID, _ sets: Int, seconds: ClosedRange<Int>) -> Prescription {
        Prescription(exercise: exercise, sets: sets, target: seconds, unit: .seconds)
    }

    func withSets(_ sets: Int) -> Prescription {
        Prescription(exercise: exercise, sets: sets, target: target, unit: unit, perSide: perSide)
    }
}

enum WorkoutKind: String, Sendable {
    case a, b, upper1, lower1, upper2, lower2

    var title: String {
        switch self {
        case .a: String(localized: "Workout A")
        case .b: String(localized: "Workout B")
        case .upper1: String(localized: "Upper body 1")
        case .lower1: String(localized: "Lower body 1")
        case .upper2: String(localized: "Upper body 2")
        case .lower2: String(localized: "Lower body 2")
        }
    }
}

struct WorkoutTemplate: Hashable, Sendable {
    let kind: WorkoutKind
    let items: [Prescription]
}

struct Phase: Sendable {
    /// Workouts in the order they rotate: A, B, A, B… or upper, lower, upper, lower.
    let workouts: [WorkoutTemplate]
}

struct Program: Sendable {
    let daysPerWeek: Int
    let phases: [Phase]

    static func forDays(_ days: Int) -> Program {
        switch days {
        case 2: twoDay
        case 4: fourDay
        default: threeDay
        }
    }

    static func phaseName(_ index: Int) -> String {
        switch index {
        case 0: String(localized: "Machines")
        case 1: String(localized: "Dumbbells")
        default: String(localized: "Barbell")
        }
    }

    /// Seconds of rest between sets in each phase.
    static func restSeconds(phase: Int) -> Int {
        [75, 90, 120][min(phase, 2)]
    }
}

// MARK: - The programs (draft, waiting for the coaches' review)

extension Program {
    /// Full body three times a week, A and B alternating.
    static let threeDay = Program(daysPerWeek: 3, phases: [
        Phase(workouts: [
            WorkoutTemplate(kind: .a, items: [
                .reps(.legPress, 3, 10...12),
                .reps(.chestPress, 3, 10...12),
                .reps(.latPulldown, 3, 10...12),
                .reps(.legCurl, 2, 10...12),
                .reps(.tricepsPushdown, 2, 12...15),
                .hold(.plank, 2, seconds: 20...30),
            ]),
            WorkoutTemplate(kind: .b, items: [
                .reps(.legPress, 3, 10...12),
                .reps(.seatedCableRow, 3, 10...12),
                .reps(.machineShoulderPress, 3, 10...12),
                .reps(.gluteBridge, 3, 10...12),
                .reps(.cableCurl, 2, 12...15),
                .reps(.deadBug, 2, 6...8, perSide: true),
            ]),
        ]),
        Phase(workouts: [
            WorkoutTemplate(kind: .a, items: [
                .reps(.gobletSquat, 3, 8...12),
                .reps(.dumbbellBench, 3, 8...12),
                .reps(.latPulldown, 3, 8...12),
                .reps(.dumbbellRDL, 3, 10...12),
                .reps(.tricepsPushdown, 2, 12...15),
                .hold(.plank, 3, seconds: 30...40),
            ]),
            WorkoutTemplate(kind: .b, items: [
                .reps(.legPress, 3, 10...12),
                .reps(.oneArmRow, 3, 10...12, perSide: true),
                .reps(.dumbbellShoulderPress, 3, 8...12),
                .reps(.splitSquat, 2, 8...10, perSide: true),
                .reps(.lateralRaise, 2, 12...15),
                .reps(.dumbbellCurl, 2, 10...12),
            ]),
        ]),
        Phase(workouts: [
            WorkoutTemplate(kind: .a, items: [
                .reps(.backSquat, 3, 6...10),
                .reps(.benchPress, 3, 6...10),
                .reps(.latPulldown, 3, 8...10),
                .reps(.dumbbellRDL, 2, 10...12),
                .reps(.tricepsPushdown, 2, 12...15),
                .hold(.plank, 3, seconds: 40...45),
            ]),
            WorkoutTemplate(kind: .b, items: [
                .reps(.barbellRDL, 3, 8...10),
                .reps(.barbellRow, 3, 8...10),
                .reps(.dumbbellShoulderPress, 3, 8...10),
                .reps(.legPress, 2, 10...12),
                .reps(.lateralRaise, 2, 12...15),
                .reps(.deadBug, 2, 8...8, perSide: true),
            ]),
        ]),
    ])

    /// The same A and B once a week each, with one more set on the first two exercises.
    static let twoDay = Program(daysPerWeek: 2, phases: threeDay.phases.map { phase in
        Phase(workouts: phase.workouts.map { workout in
            WorkoutTemplate(kind: workout.kind, items: workout.items.enumerated().map { index, item in
                index < 2 ? item.withSets(item.sets + 1) : item
            })
        })
    })

    /// Upper / lower split. Phases 2 and 3 swap machines for free weights.
    static let fourDay: Program = {
        let machines = Phase(workouts: [
            WorkoutTemplate(kind: .upper1, items: [
                .reps(.chestPress, 3, 10...12),
                .reps(.latPulldown, 3, 10...12),
                .reps(.machineShoulderPress, 2, 10...12),
                .reps(.seatedCableRow, 2, 10...12),
                .reps(.tricepsPushdown, 2, 12...15),
                .reps(.cableCurl, 2, 12...15),
            ]),
            WorkoutTemplate(kind: .lower1, items: [
                .reps(.legPress, 3, 10...12),
                .reps(.legCurl, 3, 10...12),
                .reps(.gluteBridge, 3, 10...12),
                .reps(.legExtension, 2, 12...15),
                .reps(.backExtension, 2, 10...12),
                .hold(.plank, 2, seconds: 20...30),
            ]),
            WorkoutTemplate(kind: .upper2, items: [
                .reps(.assistedPullUp, 3, 6...10),
                .reps(.machineShoulderPress, 3, 10...12),
                .reps(.seatedCableRow, 3, 10...12),
                .reps(.chestPress, 2, 12...15),
                .reps(.cableCurl, 2, 12...15),
                .reps(.tricepsPushdown, 2, 12...15),
            ]),
            WorkoutTemplate(kind: .lower2, items: [
                .reps(.gluteBridge, 3, 10...12),
                .reps(.legPress, 3, 12...15),
                .reps(.legCurl, 2, 12...15),
                .reps(.legExtension, 2, 12...15),
                .reps(.backExtension, 2, 10...12),
                .reps(.deadBug, 2, 6...8, perSide: true),
            ]),
        ])
        return Program(daysPerWeek: 4, phases: [machines, machines.upgraded(to: 1), machines.upgraded(to: 2)])
    }()
}

private extension Phase {
    /// The swap table from the coach doc: machine → dumbbell → barbell.
    func upgraded(to phase: Int) -> Phase {
        Phase(workouts: workouts.map { workout in
            WorkoutTemplate(kind: workout.kind, items: workout.items.map { $0.upgraded(to: phase) })
        })
    }
}

private extension Prescription {
    func upgraded(to phase: Int) -> Prescription {
        let dumbbells = phase == 1
        switch exercise {
        case .legPress:
            return dumbbells ? .reps(.gobletSquat, sets, 8...12) : .reps(.backSquat, sets, 6...10)
        case .chestPress:
            return dumbbells ? .reps(.dumbbellBench, sets, 8...12) : .reps(.benchPress, sets, 6...10)
        case .seatedCableRow:
            return dumbbells ? .reps(.oneArmRow, sets, 10...12, perSide: true) : .reps(.barbellRow, sets, 8...10)
        case .machineShoulderPress:
            return .reps(.dumbbellShoulderPress, sets, dumbbells ? 8...12 : 8...10)
        case .backExtension:
            return dumbbells ? .reps(.dumbbellRDL, sets, 10...12) : .reps(.barbellRDL, sets, 8...10)
        case .legExtension:
            return .reps(.splitSquat, sets, 8...10, perSide: true)
        case .cableCurl:
            return .reps(.dumbbellCurl, sets, 10...12)
        default:
            return self
        }
    }
}
