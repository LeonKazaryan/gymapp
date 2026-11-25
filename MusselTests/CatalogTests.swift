import CoreGraphics
import Testing
@testable import Mussel

struct CatalogTests {
    @Test(arguments: ExerciseID.allCases)
    func everyExerciseIsComplete(_ id: ExerciseID) {
        let exercise = Exercise.with(id)
        #expect(!exercise.muscles.isEmpty)
        #expect(exercise.technique.cues.count == 3)
        #expect(!exercise.technique.mistake.isEmpty)
        #expect(Demos.all[id] != nil)
        if let alternative = exercise.alternative {
            #expect(alternative != id)
        }
    }

    @Test func programsOnlyUseCatalogExercises() {
        for days in [2, 3, 4] {
            let program = Program.forDays(days)
            #expect(program.phases.count == 3)
            for item in program.phases.flatMap(\.workouts).flatMap(\.items) {
                #expect(Demos.all[item.exercise] != nil)
            }
        }
    }

    @Test func twoDayProgramAddsASetToTheFirstTwoExercises() {
        let three = Program.threeDay.phases[0].workouts[0].items
        let two = Program.twoDay.phases[0].workouts[0].items
        #expect(two[0].sets == three[0].sets + 1)
        #expect(two[1].sets == three[1].sets + 1)
        #expect(two[2].sets == three[2].sets)
    }

    @Test func summariesReadLikeTheCoachDoc() {
        #expect(Prescription.reps(.legPress, 3, 10...12).summary == "3 × 10–12")
        #expect(Prescription.reps(.deadBug, 2, 8...8, perSide: true).summary.hasPrefix("2 × 8 "))
    }
}

struct DemoTests {
    /// Hands and feet that reach for a handle or a spot on the floor must get there, or the
    /// figure floats next to the machine.
    @Test(arguments: ExerciseID.allCases)
    func reachingLimbsArriveAtTheirTargets(_ id: ExerciseID) {
        let demo = Demos.of(id)
        for pose in [demo.start] + demo.ends {
            let skeleton = Skeleton(pose, camera: demo.camera)
            let arms = zip(pose.arms, skeleton.arms).enumerated().map { ($0, $1.0, $1.1, "arm") }
            let legs = zip(pose.legs, skeleton.legs).enumerated().map { ($0, $1.0, $1.1, "leg") }
            for (index, limb, chain, kind) in arms + legs {
                guard case let .reach(.point(target), _) = limb else { continue }
                // Far limbs are drawn shifted for depth from the side.
                let isFar = demo.camera == .side && index == 1
                let end = isFar ? chain.end - Body.depth : chain.end
                let miss = (end - target).length
                #expect(miss < 0.02, "\(id) \(kind) misses its target by \(miss)")
            }
        }
    }

    @Test(arguments: ExerciseID.allCases)
    func everyFrameIsFinite(_ id: ExerciseID) {
        let demo = Demos.of(id)
        for end in demo.ends.indices {
            for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                let s = Skeleton(demo.pose(at: DemoMoment(end: end, progress: progress)), camera: demo.camera)
                let points = [s.hip, s.neck, s.head] + (s.arms + s.legs).flatMap { [$0.joint, $0.end] }
                #expect(points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
            }
        }
        #expect(demo.bounds.width > 0.3 && demo.bounds.height > 0.3)
    }

    @Test func tempoSlowsTheLowering() {
        #expect(Tempo.liftFirst.beats.back > Tempo.liftFirst.beats.go)
        #expect(Tempo.lowerFirst.beats.go > Tempo.lowerFirst.beats.back)
    }
}
