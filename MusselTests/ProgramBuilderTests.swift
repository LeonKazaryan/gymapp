import Foundation
import Testing
@testable import Mussel

/// Every onboarding answer has to change something real in the program.
struct ProgramBuilderTests {
    func build(_ change: (inout TrainingProfile) -> Void = { _ in }) -> PersonalProgram {
        var profile = TrainingProfile()
        change(&profile)
        return ProgramBuilder.build(profile)
    }

    func exercises(_ program: Program) -> [ExerciseID] {
        program.phases.flatMap(\.workouts).flatMap(\.items).map(\.exercise)
    }

    func sets(_ program: Program, phase: Int, where muscles: Set<Muscle>) -> Int {
        program.phases[phase].workouts.flatMap(\.items)
            .filter { !muscles.isDisjoint(with: Exercise.with($0.exercise).muscles) }
            .reduce(0) { $0 + $1.sets }
    }

    func totalSets(_ program: Program, phase: Int) -> Int {
        program.phases[phase].workouts.flatMap(\.items).reduce(0) { $0 + $1.sets }
    }

    @Test func noAnswersGiveTheBaseProgram() {
        let base = Program.threeDay
        let built = build()
        #expect(exercises(built.program) == exercises(base))
        #expect(built.program.phaseWeeks == [4, 4, 4] && built.notes.isEmpty)
    }

    @Test(arguments: [2, 3, 4])
    func glutesFocusMovesArmWorkToGlutesAndKeepsTheVolume(_ days: Int) {
        let balanced = build { $0.daysPerWeek = days }.program
        let glutes = build { $0.daysPerWeek = days; $0.focus = .glutesLegs }
        for phase in 0..<3 {
            #expect(sets(glutes.program, phase: phase, where: [.glutes]) > sets(balanced, phase: phase, where: [.glutes]))
            #expect(sets(glutes.program, phase: phase, where: [.biceps, .triceps]) < sets(balanced, phase: phase, where: [.biceps, .triceps]))
            #expect(abs(totalSets(glutes.program, phase: phase) - totalSets(balanced, phase: phase)) <= 2)
        }
        #expect(glutes.notes.contains(.focus(.glutesLegs)))
    }

    @Test func upperFocusAddsChestAndBackWork() {
        let balanced = build().program
        let upper = build { $0.focus = .upper }.program
        for phase in 0..<3 {
            #expect(sets(upper, phase: phase, where: [.chest, .lats, .upperBack]) > sets(balanced, phase: phase, where: [.chest, .lats, .upperBack]))
        }
    }

    @Test func womenGetGlutesSuggestedAndCanChangeIt() {
        #expect(Focus.suggested(for: .female) == .glutesLegs)
        #expect(Focus.suggested(for: .male) == .balanced)
        #expect(Focus.suggested(for: nil) == .balanced)
    }

    @Test func strengthMeansFewerRepsAndLongerRestsOnBigMoves() throws {
        let strong = build { $0.goal = .stronger }.program
        let squat = try #require(strong.phases[2].workouts.flatMap(\.items).first { $0.exercise == .backSquat })
        #expect(squat.target == 6...8)
        #expect(strong.rest[2] > Program.threeDay.rest[2])
        // Machines stay at 10–12 while the moves are learned.
        #expect(strong.phases[0].workouts[0].items[0].target == 10...12)
    }

    @Test func shapeMeansMoreRepsOnSmallMoves() throws {
        let shape = build { $0.goal = .shape }.program
        let pushdown = try #require(shape.phases[0].workouts.flatMap(\.items).first { $0.exercise == .tricepsPushdown })
        #expect(pushdown.target == 12...15)
        #expect(shape.rest[0] < Program.threeDay.rest[0])
    }

    @Test func experienceAndAgeChangeHowLongTheMachinesLast() {
        #expect(build { $0.experience = .before }.program.phaseWeeks[0] == 2)
        #expect(build { $0.goal = .confidence }.program.phaseWeeks[0] == 6)
        #expect(build { $0.age = 58; $0.experience = .before }.program.phaseWeeks[0] == 6)
    }

    @Test(arguments: [14, 55])
    func noBarbellForTheYoungAndOlder(_ age: Int) {
        let built = build { $0.age = age }
        #expect(!exercises(built.program).contains { Exercise.with($0).equipment == .barbell })
        #expect(built.notes.contains(.noBarbell(minor: age < 16)))
    }

    @Test func sessionLengthChangesTheNumberOfExercises() {
        let short = build { $0.sessionMinutes = 45 }.program
        let long = build { $0.sessionMinutes = 75 }.program
        #expect(short.phases.flatMap(\.workouts).allSatisfy { $0.items.count == 5 })
        #expect(long.phases.flatMap(\.workouts).allSatisfy { $0.items.count == 7 })
        // The extra move goes before the core work that closes the workout.
        #expect(long.phases[0].workouts[0].items.last?.exercise == .plank)
    }

    @Test func switchedOffAndMissingExercisesAreSwapped() {
        let built = build { $0.unavailable = [.legPress, .tricepsPushdown] }
        let ids = exercises(built.program)
        #expect(!ids.contains(.legPress) && !ids.contains(.tricepsPushdown))
        #expect(ids.contains(.overheadExtension))
        #expect(built.notes.contains { if case .swapped = $0 { true } else { false } })
    }

    @Test func swapsToOneSidedMovesCountRepsPerSide() throws {
        let built = build { $0.unavailable = [.seatedCableRow] }
        let row = try #require(built.program.phases[0].workouts.flatMap(\.items).first { $0.exercise == .oneArmRow })
        #expect(row.perSide)
    }

    @Test func aShortFirstPhaseEndsSooner() {
        var profile = TrainingProfile()
        profile.experience = .before
        let program = ProgramBuilder.build(profile).program
        let day0 = Date(timeIntervalSince1970: 1_800_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var log = TrainingLog(phase: 0, phaseStart: day0, workoutsInPhase: Coach.phaseQuota(daysPerWeek: 3, weeks: 2))
        log.history = [WorkoutRecord(date: day0.addingTimeInterval(13 * 86_400), duration: 0, phase: 0, kind: .a, exercises: [])]
        let next = Coach.plan(log, program: program, on: day0.addingTimeInterval(14 * 86_400), calendar: calendar)
        #expect(next.phase == 1)
    }
}
