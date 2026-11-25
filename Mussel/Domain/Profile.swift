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
