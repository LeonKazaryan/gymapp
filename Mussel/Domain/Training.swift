import Foundation

/// The answer to "How many more reps could you have done?", asked after each set the first
/// time someone does an exercise, to find their working weight.
enum RepsLeft: String, Codable, CaseIterable, Sendable {
    /// 0–1: too heavy.
    case few
    /// 2–3: the working weight.
    case some
    /// 4 or more: too light.
    case plenty
}

/// How an exercise felt, asked once after its last set.
enum Feeling: String, Codable, CaseIterable, Sendable {
    case easy, normal, hard
}

struct SetRecord: Codable, Hashable, Sendable {
    /// Kilograms; 0 for bodyweight moves.
    var weight: Double
    /// Reps, or seconds for a hold.
    var reps: Int
}

struct ExerciseRecord: Codable, Hashable, Sendable {
    enum Outcome: String, Codable, Sendable {
        case done
        case skipped
        /// Stopped with the "It hurts" button.
        case pain
    }

    /// What was actually done: the exercise may be a swap for the programmed one.
    var prescription: Prescription
    var sets: [SetRecord]
    var feeling: Feeling?
    var outcome: Outcome
    /// The working weight found the first time with this exercise.
    var calibratedWeight: Double?

    var exercise: ExerciseID { prescription.exercise }
}

struct WorkoutRecord: Codable, Identifiable, Sendable {
    var id = UUID()
    var date: Date
    var duration: TimeInterval
    var phase: Int
    var kind: WorkoutKind
    var exercises: [ExerciseRecord]
}

/// What the app has learned about one exercise for this person.
struct ExerciseProgress: Codable, Hashable, Sendable {
    var weight: Double
    /// Reps (or seconds) to aim for next time in every set.
    var targetReps: Int
    /// "Hard" twice in a row makes the weight lighter.
    var hardInARow = 0
    /// Times the person stopped with "It hurts".
    var painCount = 0
}

/// Everything about someone's training, saved on the device.
struct TrainingLog: Codable, Sendable {
    /// The current phase: 0 machines, 1 dumbbells, 2 barbell.
    var phase = 0
    var phaseStart: Date?
    /// Workouts done since the phase started. They also pick whose turn it is: A or B.
    var workoutsInPhase = 0
    var progress: [ExerciseID: ExerciseProgress] = [:]
    var history: [WorkoutRecord] = []

    var lastWorkout: Date? { history.last?.date }
}

/// Coming back after a break, from the coach doc.
enum Comeback: Sendable, Equatable {
    /// Two or three weeks off: everything 10% lighter.
    case lighter
    /// Four weeks or more off: 20% lighter and the phase starts over.
    case restart

    var fraction: Double { self == .lighter ? 0.1 : 0.2 }

    static func after(days: Int) -> Comeback? {
        days >= 28 ? .restart : days >= 14 ? .lighter : nil
    }
}

extension Exercise {
    /// One step harder: heavier, or less help on an assisted machine.
    func harder(_ weight: Double, steps: Int = 1) -> Double {
        tidy(equipment == .assisted ? max(0, weight - step * Double(steps)) : weight + step * Double(steps))
    }

    /// One step easier: lighter, or more help on an assisted machine. Never below zero.
    func easier(_ weight: Double, steps: Int = 1) -> Double {
        tidy(equipment == .assisted ? weight + step * Double(steps) : max(0, weight - step * Double(steps)))
    }

    /// About `fraction` easier, in whole steps and at least one.
    func easier(_ weight: Double, by fraction: Double) -> Double {
        guard step > 0 else { return weight }
        let steps = max(1, Int((weight * fraction / step).rounded()))
        return easier(weight, steps: steps)
    }

    private func tidy(_ weight: Double) -> Double {
        (weight * 100).rounded() / 100
    }

    /// Bodyweight moves have no weight to pick; they progress by reps.
    var hasWeight: Bool { step > 0 }
}
