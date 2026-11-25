import Foundation

/// A workout in progress, set by set. The screen shows `stage` and calls the actions; the
/// rules for weights live in `Coach`.
struct WorkoutRun: Sendable {
    enum Stage: Equatable, Sendable {
        /// Doing the next set of `current`.
        case lifting
        /// First time with the exercise: "How many more reps could you have done?"
        case repsLeft
        /// After the exercise's last set: "How did it feel?"
        case feeling
        case resting(until: Date)
        case finished
    }

    let plan: PlannedWorkout
    let started: Date
    private(set) var stage = Stage.lifting
    /// Which planned exercise is on.
    private(set) var index = 0
    /// The exercise being done: the planned one or its swap.
    private(set) var current: PlannedExercise
    private(set) var sets: [SetRecord] = []
    /// The weight to suggest for the next set.
    private(set) var weight: Double
    private(set) var trials = 0
    private(set) var found = false
    private(set) var records: [ExerciseRecord] = []

    init(plan: PlannedWorkout, started: Date) {
        self.plan = plan
        self.started = started
        current = plan.exercises[0]
        weight = current.weight
    }

    var isCalibrating: Bool { current.calibrate && !found }

    /// Sets this exercise takes. Finding the working weight can take up to four.
    var setCount: Int {
        let planned = current.prescription.sets
        return isCalibrating && sets.count >= planned ? min(4, sets.count + 1) : max(planned, sets.count)
    }

    var isLastExercise: Bool { index == plan.exercises.count - 1 }

    // MARK: Actions

    mutating func completeSet(weight: Double, reps: Int, at now: Date) {
        guard stage == .lifting else { return }
        sets.append(SetRecord(weight: weight, reps: reps))
        self.weight = weight
        if isCalibrating {
            stage = .repsLeft
        } else {
            afterSet(at: now)
        }
    }

    mutating func answer(_ left: RepsLeft, at now: Date) {
        guard stage == .repsLeft else { return }
        trials += 1
        let step = Coach.calibrate(current.exercise, weight: weight, answer: left, trial: trials)
        weight = step.weight
        found = step.found
        afterSet(at: now)
    }

    mutating func answer(_ feeling: Feeling, at now: Date) {
        guard stage == .feeling else { return }
        finishExercise(.done, feeling: feeling)
        moveOn(at: now, rest: true)
    }

    mutating func endRest() {
        if case .resting = stage { stage = .lifting }
    }

    mutating func addRest(_ seconds: TimeInterval) {
        if case let .resting(until) = stage { stage = .resting(until: until + seconds) }
    }

    /// The machine is taken: do the swap instead, from its first set.
    mutating func swap() {
        guard stage == .lifting, let swap = current.swaps.first else { return }
        var next = swap
        next.swaps = [currentWithoutSwaps]
        current = next
        sets = []
        weight = next.weight
        trials = 0
        found = false
    }

    /// "It hurts": stop this exercise; next time the app offers its swap.
    mutating func reportPain(at now: Date) {
        finishExercise(.pain, feeling: nil)
        moveOn(at: now, rest: false)
    }

    mutating func skip(at now: Date) {
        finishExercise(.skipped, feeling: nil)
        moveOn(at: now, rest: false)
    }

    /// The workout as it went, for the log. Exercises not reached count as skipped.
    func record(at now: Date) -> WorkoutRecord {
        var exercises = records
        if stage != .finished {
            if !sets.isEmpty {
                exercises.append(ExerciseRecord(prescription: current.prescription, sets: sets, feeling: nil, outcome: .done, calibratedWeight: current.calibrate && found ? weight : nil))
            }
            let reached = records.count + (sets.isEmpty ? 0 : 1)
            exercises += plan.exercises.dropFirst(reached).map {
                ExerciseRecord(prescription: $0.prescription, sets: [], feeling: nil, outcome: .skipped)
            }
        }
        return WorkoutRecord(date: started, duration: now.timeIntervalSince(started), phase: plan.phase, kind: plan.kind, exercises: exercises)
    }

    /// Whether anything worth saving happened.
    var hasProgress: Bool { !records.isEmpty || !sets.isEmpty }

    // MARK: Flow

    private var currentWithoutSwaps: PlannedExercise {
        var plain = current
        plain.swaps = []
        return plain
    }

    private var exerciseIsComplete: Bool {
        sets.count >= current.prescription.sets && !isCalibrating
    }

    private mutating func afterSet(at now: Date) {
        if exerciseIsComplete {
            stage = .feeling
        } else {
            stage = .resting(until: now.addingTimeInterval(TimeInterval(plan.restSeconds)))
        }
    }

    private mutating func finishExercise(_ outcome: ExerciseRecord.Outcome, feeling: Feeling?) {
        let calibrated = current.calibrate && outcome == .done ? weight : nil
        records.append(ExerciseRecord(prescription: current.prescription, sets: sets, feeling: feeling, outcome: outcome, calibratedWeight: calibrated))
    }

    private mutating func moveOn(at now: Date, rest: Bool) {
        guard !isLastExercise else {
            stage = .finished
            return
        }
        index += 1
        current = plan.exercises[index]
        sets = []
        weight = current.weight
        trials = 0
        found = false
        stage = rest ? .resting(until: now.addingTimeInterval(TimeInterval(plan.restSeconds))) : .lifting
    }
}
