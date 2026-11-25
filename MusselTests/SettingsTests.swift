import Foundation
import Testing
@testable import Mussel

@MainActor
struct SettingsTests {
    @Test func onboardingAnswersSurviveARestart() throws {
        let suite = "SettingsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = Settings(defaults: defaults)
        first.goal = .shape
        first.age = 15
        first.bodyWeight = 64
        first.health = [.injuries]
        first.missingKit = [.rack, .gravitron]
        first.daysPerWeek = 2
        first.isOnboarded = true

        let again = Settings(defaults: defaults)
        #expect(again.goal == .shape && again.age == 15 && again.bodyWeight == 64)
        #expect(again.health == [.injuries] && again.missingKit == [.rack, .gravitron])
        #expect(again.daysPerWeek == 2 && again.isOnboarded && again.isMinor)
        #expect(again.unavailableExercises.isSuperset(of: [.backSquat, .benchPress, .assistedPullUp]))

        again.bodyWeight = nil
        #expect(Settings(defaults: defaults).bodyWeight == nil)
    }
}
