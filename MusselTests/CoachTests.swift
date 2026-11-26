import Foundation
import Testing
@testable import Mussel

/// The weight and schedule rules from the coach doc.
struct CoachTests {
    let day0 = Date(timeIntervalSince1970: 1_800_000_000)
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func day(_ n: Int) -> Date { day0.addingTimeInterval(Double(n) * 86_400) }

    func plan(_ log: TrainingLog, on n: Int, days: Int = 3) -> PlannedWorkout {
        Coach.plan(log, daysPerWeek: days, on: day(n), calendar: calendar)
    }

    /// A workout where every exercise was done for all its sets at `reps`.
    func done(_ plan: PlannedWorkout, on n: Int, reps: (Prescription) -> Int, feeling: Feeling = .normal) -> WorkoutRecord {
        let exercises = plan.exercises.map { item in
            ExerciseRecord(
                prescription: item.prescription,
                sets: Array(repeating: SetRecord(weight: item.weight, reps: reps(item.prescription)), count: item.prescription.sets),
                feeling: feeling, outcome: .done, calibratedWeight: item.calibrate ? item.weight : nil
            )
        }
        return WorkoutRecord(date: day(n), duration: 3000, phase: plan.phase, kind: plan.kind, exercises: exercises)
    }

    // MARK: The first workout

    @Test func firstWorkoutIsAWithTwoSetsAndLightestWeights() throws {
        let first = plan(TrainingLog(), on: 0)
        #expect(first.phase == 0 && first.week == 1 && first.kind == .a)
        #expect(first.exercises.allSatisfy { $0.prescription.sets <= 2 })
        let legPress = try #require(first.exercises.first)
        #expect(legPress.prescription.exercise == .legPress)
        #expect(legPress.weight == Exercise.with(.legPress).startWeight)
        #expect(legPress.calibrate && legPress.targetReps == 10)
        let plank = try #require(first.exercises.last)
        #expect(!plank.calibrate)
    }

    @Test func calibrationMovesTheWeightUntilTwoOrThreeRepsAreLeft() {
        let machine = Exercise.with(.legExtension)  // 5 kg steps
        #expect(Coach.calibrate(machine, weight: 10, answer: .plenty, trial: 1) == (20, false))
        #expect(Coach.calibrate(machine, weight: 20, answer: .plenty, trial: 2) == (25, false))
        #expect(Coach.calibrate(machine, weight: 25, answer: .few, trial: 3) == (20, false))
        #expect(Coach.calibrate(machine, weight: 20, answer: .some, trial: 2) == (20, true))
        #expect(Coach.calibrate(machine, weight: 20, answer: .plenty, trial: 4) == (25, true))
    }

    @Test func workoutsTakeTurns() {
        var log = TrainingLog()
        let a = plan(log, on: 0)
        log = Coach.record(done(a, on: 0, reps: { $0.target.lowerBound }), plan: a, into: log)
        let b = plan(log, on: 2)
        #expect(b.kind == .b)
        log = Coach.record(done(b, on: 2, reps: { $0.target.lowerBound }), plan: b, into: log)
        #expect(plan(log, on: 4).kind == .a)
    }

    // MARK: Progression

    func progressed(_ exercise: ExerciseID, weight: Double, reps: [Int], range: ClosedRange<Int> = 10...12, feeling: Feeling, before: ExerciseProgress? = nil) -> ExerciseProgress {
        let record = ExerciseRecord(
            prescription: .reps(exercise, reps.count, range),
            sets: reps.map { SetRecord(weight: weight, reps: $0) }, feeling: feeling, outcome: .done
        )
        return Coach.progressed(before ?? ExerciseProgress(weight: weight, targetReps: range.lowerBound), after: record)
    }

    @Test func topOfTheRangeAddsAStepAndResetsTheReps() {
        let next = progressed(.chestPress, weight: 30, reps: [12, 12, 12], feeling: .normal)
        #expect(next.weight == 35 && next.targetReps == 10)
    }

    @Test func inTheRangeAddsARep() {
        let next = progressed(.chestPress, weight: 30, reps: [11, 10, 10], feeling: .normal)
        #expect(next.weight == 30 && next.targetReps == 11)
    }

    @Test func missingTheBottomOrHardKeepsTheWeight() {
        #expect(progressed(.chestPress, weight: 30, reps: [10, 9, 8], feeling: .normal).weight == 30)
        let hard = progressed(.chestPress, weight: 30, reps: [12, 12, 12], feeling: .hard)
        #expect(hard.weight == 30 && hard.hardInARow == 1)
    }

    @Test func hardTwiceInARowTakesTenPercentOff() {
        let before = ExerciseProgress(weight: 40, targetReps: 11, hardInARow: 1)
        let next = progressed(.chestPress, weight: 40, reps: [10, 10, 10], feeling: .hard, before: before)
        #expect(next.weight == 35 && next.targetReps == 10 && next.hardInARow == 0)
    }

    @Test func assistedMachinesGetHarderWithLessCounterweight() {
        let next = progressed(.assistedPullUp, weight: 40, reps: [10, 10, 10], range: 6...10, feeling: .easy)
        #expect(next.weight == 35)
        #expect(Exercise.with(.assistedPullUp).easier(40, by: 0.1) == 45)
    }

    @Test func bodyweightMovesProgressByRepsOnly() {
        let next = progressed(.plank, weight: 0, reps: [30, 30], range: 20...30, feeling: .easy)
        #expect(next.weight == 0 && next.targetReps == 30)
    }

    // MARK: Breaks and phases

    @Test func twoWeeksOffIsTenPercentLighter() throws {
        var log = TrainingLog()
        let first = plan(log, on: 0)
        log = Coach.record(done(first, on: 0, reps: { $0.target.lowerBound }), plan: first, into: log)
        // Leg press is in both A and B, so it's in the workout after the break too.
        let weightBefore = try #require(log.progress[.legPress]?.weight)
        let back = plan(log, on: 16)
        #expect(back.comeback == .lighter)
        let legPress = try #require(back.exercises.first { $0.prescription.exercise == .legPress })
        #expect(legPress.weight < weightBefore)
    }

    @Test func aMonthOffRestartsThePhaseAndLightensEverything() throws {
        var log = TrainingLog(phase: 1, phaseStart: day(0), workoutsInPhase: 5)
        log.progress[.dumbbellBench] = ExerciseProgress(weight: 20, targetReps: 10)
        log.history = [WorkoutRecord(date: day(10), duration: 0, phase: 1, kind: .b, exercises: [])]
        let back = plan(log, on: 45)
        #expect(back.comeback == .restart && back.phase == 1 && back.workoutsInPhase == 0 && back.kind == .a)
        log = Coach.record(WorkoutRecord(date: day(45), duration: 0, phase: 1, kind: .a, exercises: []), plan: back, into: log)
        // Not done that day, but lighter for when its turn comes.
        #expect(try #require(log.progress[.dumbbellBench]).weight == 16)
    }

    @Test func aPhaseEndsAfterFourWeeksAndThreeQuartersOfItsWorkouts() {
        let quota = Coach.phaseQuota(daysPerWeek: 3)
        #expect(quota == 9)
        var log = TrainingLog(phase: 0, phaseStart: day(0), workoutsInPhase: quota)
        log.history = [WorkoutRecord(date: day(27), duration: 0, phase: 0, kind: .a, exercises: [])]
        #expect(plan(log, on: 28).phase == 1)
        #expect(plan(log, on: 26).phase == 0)
        log.workoutsInPhase = quota - 1
        #expect(plan(log, on: 29).phase == 0)
    }

    // MARK: Pain

    @Test func afterPainTheSwapComesUpAndPainAgainMeansADoctor() throws {
        var log = TrainingLog()
        log.progress[.chestPress] = ExerciseProgress(weight: 30, targetReps: 10, painCount: 1)
        let next = plan(log, on: 0)
        let swapped = try #require(next.exercises.first { $0.replaces == .chestPress })
        #expect(swapped.prescription.exercise == Exercise.with(.chestPress).alternative)
        #expect(!swapped.hurtBefore)

        log.progress[.pushUp] = ExerciseProgress(weight: 0, targetReps: 10, painCount: 1)
        let again = plan(log, on: 0)
        let chest = try #require(again.exercises.first { $0.prescription.exercise == .chestPress })
        #expect(chest.hurtBefore)
    }
}

/// A workout played set by set.
struct WorkoutRunTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func run(calibrate: Bool) -> WorkoutRun {
        let press = PlannedExercise(prescription: .reps(.legPress, 2, 10...12), weight: 20, targetReps: 10, calibrate: calibrate)
        let row = PlannedExercise(prescription: .reps(.seatedCableRow, 2, 10...12), weight: 15, targetReps: 10, calibrate: false)
        var withSwap = press
        withSwap.swaps = [PlannedExercise(prescription: .reps(.gobletSquat, 2, 10...12), weight: 8, targetReps: 10, calibrate: true)]
        let plan = PlannedWorkout(phase: 0, phaseStart: now, workoutsInPhase: 0, week: 1, kind: .a, exercises: [withSwap, row], comeback: nil, restSeconds: 75)
        return WorkoutRun(plan: plan, started: now)
    }

    @Test func calibrationAsksAfterEverySetUntilTheWeightIsFound() {
        var run = run(calibrate: true)
        run.completeSet(weight: 20, reps: 10, at: now)
        #expect(run.stage == .repsLeft)
        run.answer(.plenty, at: now)
        #expect(run.weight == 40)
        #expect(run.stage == .resting(until: now.addingTimeInterval(75)))
        run.endRest()
        run.completeSet(weight: 40, reps: 10, at: now)
        run.answer(.plenty, at: now)
        // Two sets planned, weight not found yet: a third, trial set.
        #expect(run.setCount == 3 && run.weight == 50)
        run.endRest()
        run.completeSet(weight: 50, reps: 10, at: now)
        run.answer(.some, at: now)
        #expect(run.stage == .feeling)
        run.answer(.normal, at: now)
        #expect(run.records.first?.calibratedWeight == 50)
        #expect(run.current.prescription.exercise == .seatedCableRow)
    }

    @Test func knownExercisesGoSetRestSetFeeling() {
        var run = run(calibrate: false)
        run.completeSet(weight: 20, reps: 12, at: now)
        #expect(run.stage == .resting(until: now.addingTimeInterval(75)))
        run.addRest(15)
        #expect(run.stage == .resting(until: now.addingTimeInterval(90)))
        run.endRest()
        run.completeSet(weight: 20, reps: 11, at: now)
        #expect(run.stage == .feeling)
    }

    @Test func swapStartsTheOtherExerciseAndCanSwapBack() {
        var run = run(calibrate: false)
        run.swap()
        #expect(run.current.prescription.exercise == .gobletSquat && run.weight == 8 && run.sets.isEmpty)
        run.swap()
        #expect(run.current.prescription.exercise == .legPress)
    }

    @Test func painSkipsToTheNextExerciseAndAnEarlyExitKeepsWhatWasDone() {
        var run = run(calibrate: false)
        run.reportPain(at: now)
        #expect(run.records.first?.outcome == .pain)
        #expect(run.stage == .lifting && run.index == 1)
        run.completeSet(weight: 15, reps: 10, at: now)
        let record = run.record(at: now.addingTimeInterval(600))
        #expect(record.exercises.map(\.outcome) == [.pain, .done])
        #expect(record.duration == 600)
    }

    @Test func theLastFeelingFinishesTheWorkout() {
        var run = run(calibrate: false)
        run.skip(at: now)
        run.completeSet(weight: 15, reps: 12, at: now)
        run.endRest()
        run.completeSet(weight: 15, reps: 12, at: now)
        run.answer(.easy, at: now)
        #expect(run.stage == .finished)
    }
}

/// Kit the gym doesn't have.
struct GymKitTests {
    let day0 = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func missingMachinesUseTheirSwaps() {
        let unavailable = GymKit.unavailable([.chestPress, .legPress])
        let plan = Coach.plan(TrainingLog(), daysPerWeek: 3, unavailable: unavailable, on: day0)
        let ids = plan.exercises.map(\.prescription.exercise)
        #expect(!ids.contains(.chestPress) && !ids.contains(.legPress))
        #expect(ids.contains(.pushUp) && ids.contains(.gobletSquat))
    }

    @Test func whenTheSwapIsMissingTooTheChainGoesOn() {
        // Lat pulldown → gravitron → back to the pulldown: nothing left, so the program keeps it.
        #expect(Coach.swapChain(.latPulldown) == [.latPulldown, .assistedPullUp])
        let none = Coach.plan(TrainingLog(), daysPerWeek: 3, unavailable: GymKit.unavailable([.latPulldown, .gravitron]), on: day0)
        #expect(none.exercises.contains { $0.prescription.exercise == .latPulldown })
        // Squat rack missing: the barbell squat falls back to the goblet squat.
        #expect(Coach.swapChain(.backSquat).dropFirst().first == .gobletSquat)
    }

    @Test func theBusySwapNeverOffersMissingKit() throws {
        let plan = Coach.plan(TrainingLog(), daysPerWeek: 3, unavailable: GymKit.unavailable([.gravitron]), on: day0)
        let pulldown = try #require(plan.exercises.first { $0.prescription.exercise == .latPulldown })
        #expect(pulldown.swaps.isEmpty)
    }
}
