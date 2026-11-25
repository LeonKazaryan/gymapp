import Foundation
import Observation

/// What the person told us in onboarding, editable later in the profile. Kept on the
/// device only.
@MainActor @Observable
final class Settings {
    var daysPerWeek: Int {
        didSet { defaults.set(daysPerWeek, forKey: Key.days) }
    }

    var goal: Goal? {
        didSet { defaults.set(goal?.rawValue, forKey: Key.goal) }
    }

    var age: Int? {
        didSet { defaults.set(age, forKey: Key.age) }
    }

    /// Kilograms; optional.
    var bodyWeight: Double? {
        didSet { defaults.set(bodyWeight, forKey: Key.bodyWeight) }
    }

    var health: Set<HealthFlag> {
        didSet { defaults.set(health.map(\.rawValue), forKey: Key.health) }
    }

    /// Kit the person's gym doesn't have.
    var missingKit: Set<GymKit> {
        didSet { defaults.set(missingKit.map(\.rawValue), forKey: Key.missingKit) }
    }

    /// Exercises the program swaps out because the gym lacks their kit.
    var unavailableExercises: Set<ExerciseID> { GymKit.unavailable(missingKit) }

    /// Under 16 the coach doc asks for a coach nearby.
    var isMinor: Bool { (age ?? 99) < 16 }

    var isOnboarded: Bool {
        didSet { defaults.set(isOnboarded, forKey: Key.onboarded) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        if Debug.reset {
            for key in Key.all { defaults.removeObject(forKey: key) }
        }
        #endif
        daysPerWeek = defaults.object(forKey: Key.days) as? Int ?? 3
        isOnboarded = defaults.bool(forKey: Key.onboarded)
        goal = defaults.string(forKey: Key.goal).flatMap(Goal.init)
        age = defaults.object(forKey: Key.age) as? Int
        bodyWeight = defaults.object(forKey: Key.bodyWeight) as? Double
        health = Set((defaults.stringArray(forKey: Key.health) ?? []).compactMap(HealthFlag.init))
        missingKit = Set((defaults.stringArray(forKey: Key.missingKit) ?? []).compactMap(GymKit.init))
        #if DEBUG
        if let screen = Debug.screen, screen != "onboarding" { isOnboarded = true }
        if let days = Debug.days { daysPerWeek = days }
        #endif
    }

    private enum Key {
        static let days = "daysPerWeek"
        static let onboarded = "isOnboarded"
        static let goal = "goal"
        static let age = "age"
        static let bodyWeight = "bodyWeight"
        static let health = "health"
        static let missingKit = "missingKit"
        static let all = [days, onboarded, goal, age, bodyWeight, health, missingKit]
    }
}

#if DEBUG
/// Launch arguments for checking screens without tapping, e.g.
/// `-MusselDebugScreen exercise -MusselDebugExercise legPress`.
enum Debug {
    private static var args: UserDefaults { .standard }

    /// Forget the onboarding answers, as after a fresh install.
    static var reset: Bool { args.bool(forKey: "MusselDebugReset") }
    /// The onboarding step to open on, from 0 (welcome).
    static var onboardingStep: Int? { args.object(forKey: "MusselDebugOnboardingStep") == nil ? nil : args.integer(forKey: "MusselDebugOnboardingStep") }
    /// onboarding | program | library | exercise | workout | profile
    static var screen: String? { args.string(forKey: "MusselDebugScreen") }
    static var exercise: ExerciseID? { args.string(forKey: "MusselDebugExercise").flatMap(ExerciseID.init) }
    /// 0, 1 or 2: the phase the program screen opens on.
    static var phase: Int? { args.object(forKey: "MusselDebugPhase") == nil ? nil : args.integer(forKey: "MusselDebugPhase") }
    /// repsLeft | rest | feeling | summary: how far the workout screen plays itself.
    static var workoutStage: String? { args.string(forKey: "MusselDebugWorkoutStage") }
    static var days: Int? { args.object(forKey: "MusselDebugDays") == nil ? nil : args.integer(forKey: "MusselDebugDays") }
}
#endif
