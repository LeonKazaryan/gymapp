import Foundation

/// A line of "why the program looks like this": one per answer that changed it.
enum ProgramNote: Hashable, Sendable {
    case focus(Focus)
    case goal(Goal)
    /// Trained before: the machines phase is shorter.
    case quickStart
    /// New to it all, or 50 and over: the machines phase is longer.
    case gentleStart
    /// No barbell phase: under 16, or 50 and over.
    case noBarbell(minor: Bool)
    case shorterSessions
    case longerSessions
    /// Exercises swapped because the gym lacks the kit or the person switched them off.
    case swapped(Int)
}

struct PersonalProgram: Sendable {
    var program: Program
    var notes: [ProgramNote]
}

/// Builds someone's program from the coach-reviewed base and their answers. Every rule here
/// is a draft for the coaches, like the base programs.
enum ProgramBuilder {
    static func build(_ profile: TrainingProfile) -> PersonalProgram {
        var program = Program.forDays(profile.daysPerWeek)
        var notes: [ProgramNote] = []
        let age = profile.age ?? 30
        let minor = age < 16
        let older = age >= 50

        if profile.focus != .balanced {
            program.forEachWorkout { workout, phase in refocus(&workout, on: profile.focus, phase: phase) }
            notes.append(.focus(profile.focus))
        }

        if profile.sessionMinutes <= 45 {
            program.forEachWorkout { workout, _ in
                if workout.items.count > 5 { workout.items.removeLast() }
            }
            notes.append(.shorterSessions)
        } else if profile.sessionMinutes >= 75 {
            program.forEachWorkout { workout, phase in addAccessory(to: &workout, focus: profile.focus, phase: phase) }
            notes.append(.longerSessions)
        }

        if minor || older {
            program.forEachWorkout { workout, _ in
                for i in workout.items.indices where Exercise.with(workout.items[i].exercise).equipment == .barbell {
                    if let swap = Coach.swapChain(workout.items[i].exercise).first(where: { Exercise.with($0).equipment != .barbell }) {
                        workout.items[i] = workout.items[i].swapped(to: swap)
                    }
                }
            }
            notes.append(.noBarbell(minor: minor))
        }

        if let goal = profile.goal {
            apply(goal, to: &program)
            if goal != .confidence { notes.append(.goal(goal)) }
        }

        if profile.goal == .confidence || older {
            program.phaseWeeks[0] = 6
            notes.append(.gentleStart)
        } else if profile.experience == .before {
            program.phaseWeeks[0] = 2
            notes.append(.quickStart)
        }

        var swapped = 0
        program.forEachWorkout { workout, _ in
            for i in workout.items.indices where profile.unavailable.contains(workout.items[i].exercise) {
                if let swap = Coach.swapChain(workout.items[i].exercise).first(where: { !profile.unavailable.contains($0) }) {
                    workout.items[i] = workout.items[i].swapped(to: swap)
                    swapped += 1
                }
            }
        }
        if swapped > 0 { notes.append(.swapped(swapped)) }

        return PersonalProgram(program: program, notes: notes)
    }

    // MARK: Focus

    /// Moves work around without adding much: arms make way for glutes, or a second leg move
    /// makes way for chest and back.
    private static func refocus(_ workout: inout WorkoutTemplate, on focus: Focus, phase: Int) {
        // Full-body days count as upper days too: they're where the focus has room to move.
        let upperDay = [.a, .b, .upper1, .upper2].contains(workout.kind)
        for i in workout.items.indices {
            let item = workout.items[i]
            let present = Set(workout.items.map(\.exercise))
            switch (focus, item.exercise) {
            case (.glutesLegs, .tricepsPushdown), (.glutesLegs, .cableCurl), (.glutesLegs, .dumbbellCurl):
                let glute: Prescription = !present.contains(.gluteBridge) ? .reps(.gluteBridge, item.sets, 10...12)
                    : !present.contains(.hipAbduction) ? .reps(.hipAbduction, item.sets, 12...15)
                    : .reps(.cableKickback, item.sets, 12...15, perSide: true)
                workout.items[i] = glute
            case (.glutesLegs, .gluteBridge) where upperDay, (.glutesLegs, .dumbbellRDL) where upperDay, (.glutesLegs, .barbellRDL) where upperDay:
                // Lower days already belong to the legs; full-body days get the extra glute set.
                workout.items[i].sets = min(item.sets + 1, 4)
            case (.glutesLegs, .chestPress), (.glutesLegs, .dumbbellBench), (.glutesLegs, .benchPress):
                workout.items[i].sets = max(item.sets - 1, 2)

            case (.upper, .gluteBridge) where upperDay:
                workout.items[i] = .reps(.pecDeck, item.sets, 10...12)
            case (.upper, .splitSquat) where upperDay:
                workout.items[i] = .reps(.overheadExtension, item.sets, 10...12)
            case (.upper, .dumbbellRDL) where upperDay && phase == 2:
                workout.items[i] = .reps(.dumbbellCurl, item.sets, 10...12)
            case (.upper, .legPress) where upperDay && item.sets >= 3:
                workout.items[i].sets = item.sets - 1
            case (.upper, .chestPress), (.upper, .dumbbellBench), (.upper, .benchPress),
                 (.upper, .latPulldown), (.upper, .seatedCableRow), (.upper, .oneArmRow), (.upper, .barbellRow):
                workout.items[i].sets = min(item.sets + 1, 4)
            default:
                break
            }
        }
    }

    /// One more exercise for a 75-minute session, matching the focus.
    private static func addAccessory(to workout: inout WorkoutTemplate, focus: Focus, phase: Int) {
        let lowerDay = [.lower1, .lower2].contains(workout.kind)
        let options: [ExerciseID]
        switch (focus, lowerDay) {
        case (_, true): options = [.calfRaise, .hipAbduction]
        case (.glutesLegs, false): options = [.hipAbduction, .cableKickback, .gluteBridge]
        case (.upper, false): options = phase == 0 ? [.pecDeck, .cableCurl, .tricepsPushdown] : [.lateralRaise, .dumbbellCurl, .tricepsPushdown]
        case (.balanced, false): options = [.reverseFly, .calfRaise]
        }
        let present = Set(workout.items.map(\.exercise))
        guard let extra = options.first(where: { !present.contains($0) }) else { return }
        let item = Prescription.reps(extra, 2, extra == .pecDeck ? 10...12 : 12...15, perSide: Exercise.with(extra).isUnilateral)
        // Before the core work, which closes the workout.
        let core = workout.items.lastIndex { Exercise.with($0.exercise).muscles == [.abs] } ?? workout.items.endIndex
        workout.items.insert(item, at: core)
    }

    // MARK: Goal

    /// Strength: heavier and longer rests on the big moves once past the machines. Shape:
    /// more reps and shorter rests on the small moves.
    private static func apply(_ goal: Goal, to program: inout Program) {
        switch goal {
        case .stronger:
            program.forEachWorkout { workout, phase in
                guard phase >= 1 else { return }
                for i in workout.items.indices where workout.items[i].unit == .reps && Exercise.with(workout.items[i].exercise).isCompound {
                    workout.items[i].target = phase == 1 ? 6...10 : 6...8
                }
            }
            program.rest = [75, 120, 150]
        case .shape:
            program.forEachWorkout { workout, _ in
                for i in workout.items.indices where workout.items[i].unit == .reps && !Exercise.with(workout.items[i].exercise).isCompound {
                    workout.items[i].target = 12...15
                }
            }
            program.rest = [60, 75, 90]
        case .confidence:
            break
        }
    }
}

extension Program {
    mutating func forEachWorkout(_ body: (inout WorkoutTemplate, Int) -> Void) {
        for p in phases.indices {
            for w in phases[p].workouts.indices {
                body(&phases[p].workouts[w], p)
            }
        }
    }
}

extension Exercise {
    /// The big moves that work several joints: they take the heavy, low-rep work.
    var isCompound: Bool {
        [
            .legPress, .singleLegPress, .hackSquat, .smithSquat, .gobletSquat, .splitSquat, .backSquat,
            .dumbbellRDL, .barbellRDL, .chestPress, .plateChestPress, .dumbbellBench, .benchPress, .pushUp, .assistedDip,
            .latPulldown, .assistedPullUp, .seatedCableRow, .machineRow, .oneArmRow, .barbellRow,
            .machineShoulderPress, .dumbbellShoulderPress,
        ].contains(id)
    }

    /// Done one side at a time, so reps count per side.
    var isUnilateral: Bool {
        [.oneArmRow, .splitSquat, .cableKickback, .standingLegCurl, .singleLegPress, .deadBug, .cableLateralRaise].contains(id)
    }
}
