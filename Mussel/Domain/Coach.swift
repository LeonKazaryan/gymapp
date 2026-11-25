import Foundation

/// One exercise of the next workout, with the weight to start from.
struct PlannedExercise: Hashable, Sendable {
    var prescription: Prescription
    /// The weight for the first set.
    var weight: Double
    /// Reps (or seconds) to aim for in each set.
    var targetReps: Int
    /// First time with this exercise: find the working weight set by set.
    var calibrate: Bool
    /// The programmed exercise this one replaces, because it hurt last time.
    var replaces: ExerciseID?
    /// Both this exercise and its swap have hurt before: time to see a doctor.
    var hurtBefore = false
    /// What to do instead when the machine is taken. Empty or one.
    var swaps: [PlannedExercise] = []

    var exercise: Exercise { .with(prescription.exercise) }
}

struct PlannedWorkout: Identifiable, Sendable {
    var id: Date { phaseStart.addingTimeInterval(Double(workoutsInPhase)) }

    var phase: Int
    var phaseStart: Date
    /// Workouts already done in this phase.
    var workoutsInPhase: Int
    /// Week of the phase, from 1.
    var week: Int
    var kind: WorkoutKind
    var exercises: [PlannedExercise]
    var comeback: Comeback?

    var restSeconds: Int { Program.restSeconds(phase: phase) }
}

/// The rules from the coach doc: which workout is next, what weight to start from, and how
/// the weight changes after each workout. No UI, no storage.
enum Coach {
    /// A phase lasts at least four weeks and until 75% of its workouts are done.
    static func phaseQuota(daysPerWeek: Int) -> Int {
        Int((Double(4 * daysPerWeek) * 0.75).rounded(.up))
    }

    /// The next workout on `date`.
    static func plan(_ log: TrainingLog, daysPerWeek: Int, on date: Date, calendar: Calendar = .current) -> PlannedWorkout {
        let comeback = log.lastWorkout.flatMap { Comeback.after(days: days(from: $0, to: date, calendar)) }
        var phase = log.phase
        var phaseStart = log.phaseStart ?? date
        var done = log.workoutsInPhase
        if comeback == .restart {
            phaseStart = date
            done = 0
        } else if phase < 2, days(from: phaseStart, to: date, calendar) >= 28, done >= phaseQuota(daysPerWeek: daysPerWeek) {
            phase += 1
            phaseStart = date
            done = 0
        }
        let week = days(from: phaseStart, to: date, calendar) / 7 + 1
        let workouts = Program.forDays(daysPerWeek).phases[phase].workouts
        let template = workouts[done % workouts.count]
        let firstWeek = phase == 0 && week == 1 && log.history.count < daysPerWeek
        let exercises = template.items.map { item in
            planned(firstWeek ? item.withSets(min(item.sets, 2)) : item, log: log, comeback: comeback)
        }
        return PlannedWorkout(
            phase: phase, phaseStart: phaseStart, workoutsInPhase: done, week: week,
            kind: template.kind, exercises: exercises, comeback: comeback
        )
    }

    private static func planned(_ item: Prescription, log: TrainingLog, comeback: Comeback?) -> PlannedExercise {
        // After "It hurts", the swap comes up instead, unless it has hurt too.
        let candidates = [item.exercise] + [Exercise.with(item.exercise).alternative].compactMap { $0 }
        let painFree = candidates.first { (log.progress[$0]?.painCount ?? 0) == 0 }
        let chosen = painFree ?? item.exercise
        var plan = start(item.swapped(to: chosen), log: log, comeback: comeback)
        plan.replaces = chosen == item.exercise ? nil : item.exercise
        plan.hurtBefore = painFree == nil
        if let swap = Exercise.with(chosen).alternative, swap != item.exercise || chosen == item.exercise {
            plan.swaps = [start(item.swapped(to: swap), log: log, comeback: comeback)]
        }
        return plan
    }

    private static func start(_ item: Prescription, log: TrainingLog, comeback: Comeback?) -> PlannedExercise {
        let exercise = Exercise.with(item.exercise)
        let range = item.target
        guard let progress = log.progress[item.exercise] else {
            // First time: the lightest weight for 10 reps, then adjust set by set.
            return PlannedExercise(
                prescription: item, weight: exercise.startWeight,
                targetReps: exercise.hasWeight ? 10 : range.lowerBound, calibrate: exercise.hasWeight
            )
        }
        var weight = progress.weight
        if let comeback {
            weight = exercise.easier(weight, by: comeback.fraction)
        }
        return PlannedExercise(
            prescription: item, weight: weight,
            targetReps: min(max(progress.targetReps, range.lowerBound), range.upperBound), calibrate: false
        )
    }

    // MARK: Finding the working weight

    /// The next set's weight after a calibration answer, and whether the search is over.
    /// The first set is the machine's lightest, so "4 or more" there means very easy: two steps.
    static func calibrate(_ exercise: Exercise, weight: Double, answer: RepsLeft, trial: Int) -> (weight: Double, found: Bool) {
        let fixed = trial >= 4
        switch answer {
        case .some: return (weight, true)
        case .plenty: return (exercise.harder(weight, steps: trial == 1 ? 2 : 1), fixed)
        case .few: return (exercise.easier(weight), fixed)
        }
    }

    // MARK: After a workout

    /// The log with a finished workout in it: the phase moves on and every exercise done
    /// gets its weight and reps for next time.
    static func record(_ workout: WorkoutRecord, plan: PlannedWorkout, into log: TrainingLog) -> TrainingLog {
        var log = log
        log.phase = plan.phase
        log.phaseStart = plan.phaseStart
        log.workoutsInPhase = plan.workoutsInPhase + 1
        if let comeback = plan.comeback {
            for (id, progress) in log.progress {
                log.progress[id]?.weight = Exercise.with(id).easier(progress.weight, by: comeback.fraction)
            }
        }
        for record in workout.exercises {
            let previous = log.progress[record.exercise]
            switch record.outcome {
            case .pain:
                var progress = previous ?? ExerciseProgress(weight: Exercise.with(record.exercise).startWeight, targetReps: record.prescription.target.lowerBound)
                progress.painCount += 1
                log.progress[record.exercise] = progress
            case .skipped:
                break
            case .done:
                guard !record.sets.isEmpty else { continue }
                log.progress[record.exercise] = progressed(previous, after: record)
            }
        }
        log.history.append(workout)
        return log
    }

    /// Weight and reps for next time. Weight and reps never grow together.
    static func progressed(_ previous: ExerciseProgress?, after record: ExerciseRecord) -> ExerciseProgress {
        let exercise = Exercise.with(record.exercise)
        let range = record.prescription.target
        let lastWeight = record.sets.last?.weight ?? 0
        var progress = previous ?? ExerciseProgress(weight: lastWeight, targetReps: range.lowerBound)
        progress.weight = record.calibratedWeight ?? lastWeight
        progress.hardInARow = record.feeling == .hard ? progress.hardInARow + 1 : 0

        if record.calibratedWeight != nil {
            // Just found: start the range from the bottom.
            progress.targetReps = range.lowerBound
            return progress
        }
        let reps = record.sets.map(\.reps)
        let allAtTop = reps.count >= record.prescription.sets && reps.allSatisfy { $0 >= range.upperBound }
        let missedBottom = reps.contains { $0 < range.lowerBound }

        if progress.hardInARow >= 2 {
            progress.weight = exercise.easier(progress.weight, by: 0.1)
            progress.targetReps = range.lowerBound
            progress.hardInARow = 0
        } else if record.feeling == .hard || missedBottom {
            progress.targetReps = min(max(progress.targetReps, range.lowerBound), range.upperBound)
        } else if allAtTop && exercise.hasWeight {
            progress.weight = exercise.harder(progress.weight)
            progress.targetReps = range.lowerBound
        } else {
            let worst = reps.min() ?? range.lowerBound
            progress.targetReps = min(range.upperBound, max(worst, range.lowerBound) + 1)
        }
        return progress
    }

    static func days(from start: Date, to end: Date, _ calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }
}

extension Prescription {
    func swapped(to exercise: ExerciseID) -> Prescription {
        Prescription(exercise: exercise, sets: sets, target: target, unit: unit, perSide: perSide)
    }
}
