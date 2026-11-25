import Foundation
import Observation

/// What the person chose in onboarding. Kept on the device only.
@MainActor @Observable
final class Settings {
    var daysPerWeek: Int {
        didSet { defaults.set(daysPerWeek, forKey: Key.days) }
    }

    var isOnboarded: Bool {
        didSet { defaults.set(isOnboarded, forKey: Key.onboarded) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        if Debug.reset {
            defaults.removeObject(forKey: Key.days)
            defaults.removeObject(forKey: Key.onboarded)
        }
        #endif
        daysPerWeek = defaults.object(forKey: Key.days) as? Int ?? 3
        isOnboarded = defaults.bool(forKey: Key.onboarded)
        #if DEBUG
        if let screen = Debug.screen, screen != "onboarding" { isOnboarded = true }
        if let days = Debug.days { daysPerWeek = days }
        #endif
    }

    private enum Key {
        static let days = "daysPerWeek"
        static let onboarded = "isOnboarded"
    }
}

#if DEBUG
/// Launch arguments for checking screens without tapping, e.g.
/// `-MusselDebugScreen exercise -MusselDebugExercise legPress`.
enum Debug {
    private static var args: UserDefaults { .standard }

    /// Forget the onboarding answers, as after a fresh install.
    static var reset: Bool { args.bool(forKey: "MusselDebugReset") }
    /// onboarding | program | library | exercise | workout
    static var screen: String? { args.string(forKey: "MusselDebugScreen") }
    static var exercise: ExerciseID? { args.string(forKey: "MusselDebugExercise").flatMap(ExerciseID.init) }
    /// 0, 1 or 2: the phase the program screen opens on.
    static var phase: Int? { args.object(forKey: "MusselDebugPhase") == nil ? nil : args.integer(forKey: "MusselDebugPhase") }
    /// repsLeft | rest | feeling | summary: how far the workout screen plays itself.
    static var workoutStage: String? { args.string(forKey: "MusselDebugWorkoutStage") }
    static var days: Int? { args.object(forKey: "MusselDebugDays") == nil ? nil : args.integer(forKey: "MusselDebugDays") }
}
#endif
