import Foundation

/// What changes next time for an exercise, shown when a workout is done.
struct NextTime: Hashable, Sendable {
    enum Change: Hashable, Sendable {
        /// The first time: the working weight was found.
        case found(Double)
        case heavier(from: Double, to: Double)
        case lighter(from: Double, to: Double)
        /// Same weight, one more rep (or second) to aim for.
        case moreReps(Int, RepUnit)
        case same
        /// It hurt: the swap comes up next time.
        case swap
    }

    let exercise: ExerciseID
    let change: Change
}

extension Coach {
    static func nextTime(after workout: WorkoutRecord, before: TrainingLog, after: TrainingLog) -> [NextTime] {
        workout.exercises.compactMap { record in
            let id = record.exercise
            let old = before.progress[id]
            guard let new = after.progress[id] else { return nil }
            switch record.outcome {
            case .skipped: return nil
            case .pain: return NextTime(exercise: id, change: .swap)
            case .done: break
            }
            if record.calibratedWeight != nil, old == nil {
                return NextTime(exercise: id, change: .found(new.weight))
            }
            let previous = old?.weight ?? new.weight
            let exercise = Exercise.with(id)
            if new.weight != previous {
                let harder = exercise.harder(previous) == new.weight || (exercise.equipment == .assisted ? new.weight < previous : new.weight > previous)
                return NextTime(exercise: id, change: harder ? .heavier(from: previous, to: new.weight) : .lighter(from: previous, to: new.weight))
            }
            if new.targetReps > (old?.targetReps ?? record.prescription.target.lowerBound) {
                return NextTime(exercise: id, change: .moreReps(new.targetReps, record.prescription.unit))
            }
            return NextTime(exercise: id, change: .same)
        }
    }
}

/// Weights and reps as people read them.
enum Format {
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    static func kg(_ value: Double) -> String {
        String(localized: "\(number(value)) kg")
    }

    static func reps(_ count: Int, _ unit: RepUnit) -> String {
        unit == .seconds ? String(localized: "\(count) s") : String(localized: "\(count) reps")
    }
}
