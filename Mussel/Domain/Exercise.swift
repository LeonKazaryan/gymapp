import Foundation

enum Muscle: String, CaseIterable, Sendable {
    case chest, shoulders, rearDelts, triceps, biceps, lats, upperBack, lowerBack, abs, glutes, quads, hamstrings, adductors, calves

    var name: String {
        switch self {
        case .chest: String(localized: "Chest")
        case .shoulders: String(localized: "Shoulders")
        case .rearDelts: String(localized: "Rear delts")
        case .triceps: String(localized: "Triceps")
        case .biceps: String(localized: "Biceps")
        case .lats: String(localized: "Lats")
        case .upperBack: String(localized: "Upper back")
        case .lowerBack: String(localized: "Lower back")
        case .abs: String(localized: "Abs")
        case .glutes: String(localized: "Glutes")
        case .quads: String(localized: "Quads")
        case .hamstrings: String(localized: "Hamstrings")
        case .adductors: String(localized: "Inner thighs")
        case .calves: String(localized: "Calves")
        }
    }

    /// The body part a muscle belongs to, for browsing.
    var group: MuscleGroup {
        switch self {
        case .quads, .hamstrings, .adductors, .calves: .legs
        case .glutes: .glutes
        case .chest: .chest
        case .lats, .upperBack, .lowerBack: .back
        case .shoulders, .rearDelts: .shoulders
        case .biceps, .triceps: .arms
        case .abs: .core
        }
    }
}

enum MuscleGroup: String, CaseIterable, Sendable {
    case legs, glutes, chest, back, shoulders, arms, core

    var name: String {
        switch self {
        case .legs: String(localized: "Legs")
        case .glutes: String(localized: "Glutes")
        case .chest: String(localized: "Chest")
        case .back: String(localized: "Back")
        case .shoulders: String(localized: "Shoulders")
        case .arms: String(localized: "Arms")
        case .core: String(localized: "Core")
        }
    }
}

enum Equipment: Sendable {
    case machine, cable, plateLoaded, dumbbell, barbell, bodyweight
    /// Counterweight machines: the weight helps you, so less weight is harder.
    case assisted
    /// A barbell that runs on rails.
    case smith

    var name: String {
        switch self {
        case .machine: String(localized: "Machine")
        case .cable: String(localized: "Cable")
        case .plateLoaded: String(localized: "Plate-loaded machine")
        case .dumbbell: String(localized: "Dumbbells")
        case .barbell: String(localized: "Barbell")
        case .bodyweight: String(localized: "Bodyweight")
        case .assisted: String(localized: "Assisted machine")
        case .smith: String(localized: "Smith machine")
        }
    }
}

enum ExerciseID: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable {
    case legPress, legExtension, legCurl, gluteBridge, backExtension
    case chestPress, latPulldown, assistedPullUp, seatedCableRow, machineShoulderPress
    case tricepsPushdown, cableCurl, plank, deadBug
    case gobletSquat, dumbbellRDL, splitSquat, dumbbellBench, oneArmRow
    case dumbbellShoulderPress, lateralRaise, dumbbellCurl, pushUp
    case backSquat, benchPress, barbellRDL, barbellRow
    // Machines and cables beyond the programs, for swaps and for finding your way around a gym.
    case hackSquat, smithSquat, hipAbduction, hipAdduction, calfRaise, cableKickback, floorGluteBridge
    case pecDeck, cableFly, assistedDip, machineRow, reverseFly, facePull
    case cableLateralRaise, preacherCurl, overheadExtension, abCrunch, kneeRaise
    case plateChestPress, dumbbellFly, machinePullover, dumbbellPullover, uprightRow, tricepsMachine
    case seatedLegCurl, standingLegCurl, singleLegPress, seatedCalfRaise
}

struct Exercise: Identifiable, Hashable, Sendable {
    let id: ExerciseID
    let muscles: [Muscle]
    /// 1 = machines, 2 = dumbbells and cables, 3 = barbell.
    let level: Int
    let equipment: Equipment
    /// One progression step in kg. Zero for bodyweight moves, which progress by reps.
    let step: Double
    /// Weight for the very first set, before the app knows anything about the user.
    let startWeight: Double
    /// What the app offers when the machine is busy or missing.
    let alternative: ExerciseID?

    /// Dumbbell moves done with one dumbbell in each hand show the weight per hand.
    var weightIsPerHand: Bool {
        equipment == .dumbbell && ![.gobletSquat, .oneArmRow, .overheadExtension, .dumbbellPullover].contains(id)
    }

    var name: String {
        switch id {
        case .legPress: String(localized: "Leg Press")
        case .legExtension: String(localized: "Leg Extension")
        case .legCurl: String(localized: "Leg Curl")
        case .gluteBridge: String(localized: "Glute Bridge")
        case .backExtension: String(localized: "Back Extension")
        case .chestPress: String(localized: "Chest Press Machine")
        case .latPulldown: String(localized: "Lat Pulldown")
        case .assistedPullUp: String(localized: "Assisted Pull-up")
        case .seatedCableRow: String(localized: "Seated Cable Row")
        case .machineShoulderPress: String(localized: "Machine Shoulder Press")
        case .tricepsPushdown: String(localized: "Triceps Pushdown")
        case .cableCurl: String(localized: "Cable Biceps Curl")
        case .plank: String(localized: "Plank")
        case .deadBug: String(localized: "Dead Bug")
        case .gobletSquat: String(localized: "Goblet Squat")
        case .dumbbellRDL: String(localized: "Dumbbell Romanian Deadlift")
        case .splitSquat: String(localized: "Split Squat")
        case .dumbbellBench: String(localized: "Dumbbell Bench Press")
        case .oneArmRow: String(localized: "One-Arm Dumbbell Row")
        case .dumbbellShoulderPress: String(localized: "Seated Dumbbell Press")
        case .lateralRaise: String(localized: "Lateral Raise")
        case .dumbbellCurl: String(localized: "Dumbbell Curl")
        case .pushUp: String(localized: "Push-up")
        case .backSquat: String(localized: "Barbell Back Squat")
        case .benchPress: String(localized: "Barbell Bench Press")
        case .barbellRDL: String(localized: "Barbell Romanian Deadlift")
        case .barbellRow: String(localized: "Barbell Row")
        case .hackSquat: String(localized: "Hack Squat")
        case .smithSquat: String(localized: "Smith Machine Squat")
        case .hipAbduction: String(localized: "Hip Abduction Machine")
        case .hipAdduction: String(localized: "Hip Adduction Machine")
        case .calfRaise: String(localized: "Standing Calf Raise")
        case .cableKickback: String(localized: "Cable Glute Kickback")
        case .floorGluteBridge: String(localized: "Floor Glute Bridge")
        case .pecDeck: String(localized: "Pec Deck")
        case .cableFly: String(localized: "Cable Crossover")
        case .assistedDip: String(localized: "Assisted Dip")
        case .machineRow: String(localized: "Machine Row")
        case .reverseFly: String(localized: "Reverse Pec Deck")
        case .facePull: String(localized: "Face Pull")
        case .cableLateralRaise: String(localized: "Cable Lateral Raise")
        case .preacherCurl: String(localized: "Machine Preacher Curl")
        case .overheadExtension: String(localized: "Overhead Dumbbell Extension")
        case .abCrunch: String(localized: "Ab Crunch Machine")
        case .kneeRaise: String(localized: "Captain's Chair Knee Raise")
        case .plateChestPress: String(localized: "Plate-Loaded Chest Press")
        case .dumbbellFly: String(localized: "Dumbbell Fly")
        case .machinePullover: String(localized: "Machine Pullover")
        case .dumbbellPullover: String(localized: "Dumbbell Pullover")
        case .uprightRow: String(localized: "Upright Row")
        case .tricepsMachine: String(localized: "Triceps Extension Machine")
        case .seatedLegCurl: String(localized: "Seated Leg Curl")
        case .standingLegCurl: String(localized: "Standing Leg Curl")
        case .singleLegPress: String(localized: "Single-Leg Press")
        case .seatedCalfRaise: String(localized: "Seated Calf Raise")
        }
    }

    static func with(_ id: ExerciseID) -> Exercise {
        guard let exercise = all[id] else { preconditionFailure("No catalog entry for \(id)") }
        return exercise
    }

    // Draft list, waiting for the coaches' review (see the coach doc).
    static let all: [ExerciseID: Exercise] = Dictionary(uniqueKeysWithValues: [
        Exercise(id: .legPress, muscles: [.quads, .glutes], level: 1, equipment: .plateLoaded, step: 10, startWeight: 20, alternative: .gobletSquat),
        Exercise(id: .legExtension, muscles: [.quads], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .splitSquat),
        Exercise(id: .legCurl, muscles: [.hamstrings], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .gluteBridge),
        Exercise(id: .gluteBridge, muscles: [.glutes, .hamstrings], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .floorGluteBridge),
        Exercise(id: .backExtension, muscles: [.lowerBack, .glutes], level: 1, equipment: .bodyweight, step: 0, startWeight: 0, alternative: .gluteBridge),
        Exercise(id: .chestPress, muscles: [.chest, .triceps], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .pushUp),
        Exercise(id: .latPulldown, muscles: [.lats, .biceps], level: 1, equipment: .cable, step: 5, startWeight: 15, alternative: .assistedPullUp),
        Exercise(id: .assistedPullUp, muscles: [.lats, .biceps], level: 1, equipment: .assisted, step: 5, startWeight: 40, alternative: .latPulldown),
        Exercise(id: .seatedCableRow, muscles: [.upperBack, .lats], level: 1, equipment: .cable, step: 5, startWeight: 15, alternative: .oneArmRow),
        Exercise(id: .machineShoulderPress, muscles: [.shoulders, .triceps], level: 1, equipment: .machine, step: 5, startWeight: 5, alternative: .dumbbellShoulderPress),
        Exercise(id: .tricepsPushdown, muscles: [.triceps], level: 1, equipment: .cable, step: 2.5, startWeight: 10, alternative: .overheadExtension),
        Exercise(id: .cableCurl, muscles: [.biceps], level: 1, equipment: .cable, step: 2.5, startWeight: 5, alternative: .dumbbellCurl),
        Exercise(id: .plank, muscles: [.abs], level: 1, equipment: .bodyweight, step: 0, startWeight: 0, alternative: nil),
        Exercise(id: .deadBug, muscles: [.abs], level: 1, equipment: .bodyweight, step: 0, startWeight: 0, alternative: .plank),
        Exercise(id: .gobletSquat, muscles: [.quads, .glutes], level: 2, equipment: .dumbbell, step: 2, startWeight: 8, alternative: .legPress),
        Exercise(id: .dumbbellRDL, muscles: [.hamstrings, .glutes], level: 2, equipment: .dumbbell, step: 2, startWeight: 6, alternative: .backExtension),
        Exercise(id: .splitSquat, muscles: [.quads, .glutes], level: 2, equipment: .dumbbell, step: 2, startWeight: 0, alternative: .legPress),
        Exercise(id: .dumbbellBench, muscles: [.chest, .triceps], level: 2, equipment: .dumbbell, step: 2, startWeight: 6, alternative: .chestPress),
        Exercise(id: .oneArmRow, muscles: [.lats, .upperBack], level: 2, equipment: .dumbbell, step: 2, startWeight: 8, alternative: .seatedCableRow),
        Exercise(id: .dumbbellShoulderPress, muscles: [.shoulders, .triceps], level: 2, equipment: .dumbbell, step: 2, startWeight: 4, alternative: .machineShoulderPress),
        Exercise(id: .lateralRaise, muscles: [.shoulders], level: 2, equipment: .dumbbell, step: 1, startWeight: 2, alternative: .cableLateralRaise),
        Exercise(id: .dumbbellCurl, muscles: [.biceps], level: 2, equipment: .dumbbell, step: 1, startWeight: 4, alternative: .cableCurl),
        Exercise(id: .pushUp, muscles: [.chest, .triceps, .abs], level: 2, equipment: .bodyweight, step: 0, startWeight: 0, alternative: .chestPress),
        Exercise(id: .backSquat, muscles: [.quads, .glutes], level: 3, equipment: .barbell, step: 5, startWeight: 20, alternative: .gobletSquat),
        Exercise(id: .benchPress, muscles: [.chest, .triceps], level: 3, equipment: .barbell, step: 2.5, startWeight: 20, alternative: .dumbbellBench),
        Exercise(id: .barbellRDL, muscles: [.hamstrings, .glutes], level: 3, equipment: .barbell, step: 5, startWeight: 20, alternative: .dumbbellRDL),
        Exercise(id: .barbellRow, muscles: [.upperBack, .lats], level: 3, equipment: .barbell, step: 5, startWeight: 20, alternative: .oneArmRow),
        // Not in the programs yet. Plate-loaded and Smith weights count the plates only.
        Exercise(id: .hackSquat, muscles: [.quads, .glutes], level: 1, equipment: .plateLoaded, step: 10, startWeight: 0, alternative: .legPress),
        Exercise(id: .smithSquat, muscles: [.quads, .glutes], level: 2, equipment: .smith, step: 5, startWeight: 0, alternative: .gobletSquat),
        Exercise(id: .hipAbduction, muscles: [.glutes], level: 1, equipment: .machine, step: 5, startWeight: 15, alternative: .gluteBridge),
        Exercise(id: .hipAdduction, muscles: [.adductors], level: 1, equipment: .machine, step: 5, startWeight: 15, alternative: nil),
        Exercise(id: .calfRaise, muscles: [.calves], level: 1, equipment: .machine, step: 5, startWeight: 20, alternative: nil),
        Exercise(id: .cableKickback, muscles: [.glutes], level: 2, equipment: .cable, step: 2.5, startWeight: 5, alternative: .gluteBridge),
        Exercise(id: .floorGluteBridge, muscles: [.glutes, .hamstrings], level: 1, equipment: .bodyweight, step: 0, startWeight: 0, alternative: .gluteBridge),
        Exercise(id: .pecDeck, muscles: [.chest], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .cableFly),
        Exercise(id: .cableFly, muscles: [.chest], level: 2, equipment: .cable, step: 2.5, startWeight: 5, alternative: .pecDeck),
        Exercise(id: .assistedDip, muscles: [.chest, .triceps], level: 1, equipment: .assisted, step: 5, startWeight: 40, alternative: .chestPress),
        Exercise(id: .machineRow, muscles: [.upperBack, .lats], level: 1, equipment: .machine, step: 5, startWeight: 15, alternative: .seatedCableRow),
        Exercise(id: .reverseFly, muscles: [.rearDelts, .upperBack], level: 1, equipment: .machine, step: 5, startWeight: 5, alternative: .facePull),
        Exercise(id: .facePull, muscles: [.rearDelts, .upperBack], level: 1, equipment: .cable, step: 2.5, startWeight: 10, alternative: .reverseFly),
        Exercise(id: .cableLateralRaise, muscles: [.shoulders], level: 2, equipment: .cable, step: 2.5, startWeight: 2.5, alternative: .lateralRaise),
        Exercise(id: .preacherCurl, muscles: [.biceps], level: 1, equipment: .machine, step: 2.5, startWeight: 5, alternative: .cableCurl),
        Exercise(id: .overheadExtension, muscles: [.triceps], level: 2, equipment: .dumbbell, step: 2, startWeight: 6, alternative: .tricepsPushdown),
        Exercise(id: .abCrunch, muscles: [.abs], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .deadBug),
        Exercise(id: .kneeRaise, muscles: [.abs], level: 2, equipment: .bodyweight, step: 0, startWeight: 0, alternative: .deadBug),
        Exercise(id: .plateChestPress, muscles: [.chest, .triceps], level: 1, equipment: .plateLoaded, step: 5, startWeight: 10, alternative: .chestPress),
        Exercise(id: .dumbbellFly, muscles: [.chest], level: 2, equipment: .dumbbell, step: 1, startWeight: 4, alternative: .pecDeck),
        Exercise(id: .machinePullover, muscles: [.lats, .chest], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .dumbbellPullover),
        Exercise(id: .dumbbellPullover, muscles: [.lats, .chest], level: 2, equipment: .dumbbell, step: 2, startWeight: 6, alternative: .machinePullover),
        Exercise(id: .uprightRow, muscles: [.shoulders, .upperBack], level: 3, equipment: .barbell, step: 2.5, startWeight: 10, alternative: .lateralRaise),
        Exercise(id: .tricepsMachine, muscles: [.triceps], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .tricepsPushdown),
        Exercise(id: .seatedLegCurl, muscles: [.hamstrings], level: 1, equipment: .machine, step: 5, startWeight: 10, alternative: .legCurl),
        Exercise(id: .standingLegCurl, muscles: [.hamstrings], level: 1, equipment: .machine, step: 2.5, startWeight: 5, alternative: .seatedLegCurl),
        Exercise(id: .singleLegPress, muscles: [.quads, .glutes], level: 1, equipment: .plateLoaded, step: 10, startWeight: 0, alternative: .splitSquat),
        Exercise(id: .seatedCalfRaise, muscles: [.calves], level: 1, equipment: .plateLoaded, step: 5, startWeight: 10, alternative: .calfRaise),
    ].map { ($0.id, $0) })
}
