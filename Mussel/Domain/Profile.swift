import Foundation

/// Why someone came to the gym, from the coach doc's description of the user.
enum Goal: String, CaseIterable, Codable, Sendable {
    case stronger, shape, confidence

    var title: String {
        switch self {
        case .stronger: String(localized: "Get stronger")
        case .shape: String(localized: "Get in shape")
        case .confidence: String(localized: "Feel at home in the gym")
        }
    }

    var detail: String {
        switch self {
        case .stronger: String(localized: "More weight on the bar every few weeks.")
        case .shape: String(localized: "Firmer body, better posture, more energy.")
        case .confidence: String(localized: "Know which machine does what and how to use it.")
        }
    }

    /// The exercise that pictures the goal.
    var picture: ExerciseID {
        switch self {
        case .stronger: .backSquat
        case .shape: .lateralRaise
        case .confidence: .latPulldown
        }
    }
}

/// The health questions from the coach doc's safety section. Any "yes" means: see a doctor
/// first and train with a coach.
enum HealthFlag: String, CaseIterable, Codable, Sendable {
    case painNow, injuries, heart, pregnancy, surgery

    var title: String {
        switch self {
        case .painNow: String(localized: "Something hurts right now")
        case .injuries: String(localized: "Back, knee or shoulder injuries")
        case .heart: String(localized: "Heart or blood pressure problems")
        case .pregnancy: String(localized: "Pregnancy")
        case .surgery: String(localized: "Surgery in the last year")
        }
    }

    var symbol: String {
        switch self {
        case .painNow: "bolt.heart"
        case .injuries: "figure.walk.motion.trianglebadge.exclamationmark"
        case .heart: "heart.text.square"
        case .pregnancy: "figure.and.child.holdinghands"
        case .surgery: "cross.case"
        }
    }
}

/// Kit a gym may or may not have. Missing kit makes the program use the swaps.
enum GymKit: String, CaseIterable, Codable, Sendable {
    case legPress, legExtension, legCurl, hipThrust, backExtension
    case chestPress, latPulldown, gravitron, seatedRow, shoulderPress, cableColumn
    /// A squat rack with safety bars, needed for the barbell squat and bench press.
    case rack

    var name: String {
        switch self {
        case .legPress: String(localized: "Leg press")
        case .legExtension: String(localized: "Leg extension")
        case .legCurl: String(localized: "Leg curl")
        case .hipThrust: String(localized: "Hip thrust machine")
        case .backExtension: String(localized: "Back extension bench")
        case .chestPress: String(localized: "Chest press")
        case .latPulldown: String(localized: "Lat pulldown")
        case .gravitron: String(localized: "Gravitron")
        case .seatedRow: String(localized: "Seated cable row")
        case .shoulderPress: String(localized: "Shoulder press")
        case .cableColumn: String(localized: "Cable column")
        case .rack: String(localized: "Squat rack")
        }
    }

    /// The exercise its card plays.
    var picture: ExerciseID {
        switch self {
        case .legPress: .legPress
        case .legExtension: .legExtension
        case .legCurl: .legCurl
        case .hipThrust: .gluteBridge
        case .backExtension: .backExtension
        case .chestPress: .chestPress
        case .latPulldown: .latPulldown
        case .gravitron: .assistedPullUp
        case .seatedRow: .seatedCableRow
        case .shoulderPress: .machineShoulderPress
        case .cableColumn: .tricepsPushdown
        case .rack: .backSquat
        }
    }

    /// The exercises that need it.
    var exercises: Set<ExerciseID> {
        switch self {
        case .legPress: [.legPress]
        case .legExtension: [.legExtension]
        case .legCurl: [.legCurl]
        case .hipThrust: [.gluteBridge]
        case .backExtension: [.backExtension]
        case .chestPress: [.chestPress]
        case .latPulldown: [.latPulldown]
        case .gravitron: [.assistedPullUp, .assistedDip]
        case .seatedRow: [.seatedCableRow]
        case .shoulderPress: [.machineShoulderPress]
        case .cableColumn: [.tricepsPushdown, .cableCurl, .cableFly, .facePull, .cableLateralRaise, .cableKickback]
        case .rack: [.backSquat, .benchPress]
        }
    }

    static func unavailable(_ missing: Set<GymKit>) -> Set<ExerciseID> {
        missing.reduce(into: Set<ExerciseID>()) { $0.formUnion($1.exercises) }
    }
}

enum Sex: String, CaseIterable, Codable, Sendable {
    case female, male

    var title: String {
        switch self {
        case .female: String(localized: "Woman")
        case .male: String(localized: "Man")
        }
    }
}

/// What to build first. The total work stays about the same; the focus moves it around.
enum Focus: String, CaseIterable, Codable, Sendable {
    case glutesLegs, balanced, upper

    /// What most people pick, so the question comes pre-answered.
    static func suggested(for sex: Sex?) -> Focus {
        sex == .female ? .glutesLegs : .balanced
    }

    var picture: ExerciseID {
        switch self {
        case .glutesLegs: .gluteBridge
        case .balanced: .legPress
        case .upper: .chestPress
        }
    }

    var title: String {
        switch self {
        case .glutesLegs: String(localized: "Glutes and legs")
        case .balanced: String(localized: "Everything evenly")
        case .upper: String(localized: "Upper body")
        }
    }
}

enum Experience: String, CaseIterable, Codable, Sendable {
    /// Never trained.
    case none
    /// Tried a few times.
    case little
    /// Trained before, coming back.
    case before

    var title: String {
        switch self {
        case .none: String(localized: "Never")
        case .little: String(localized: "A few times")
        case .before: String(localized: "Trained before")
        }
    }
}

/// Everything the program is built from.
struct TrainingProfile: Hashable, Sendable {
    var daysPerWeek = 3
    var sex: Sex?
    var goal: Goal?
    var focus = Focus.balanced
    var experience = Experience.none
    var age: Int?
    /// 45, 60 or 75 minutes.
    var sessionMinutes = 60
    /// Missing kit and exercises the person switched off.
    var unavailable: Set<ExerciseID> = []
}
