import CoreGraphics

/// The demo of every exercise in the catalog.
///
/// Poses are in scene units (a standing figure is about 1 tall, the floor is y = 0, up is
/// negative). Angles are bone directions: 0 down, 90 forward, 180 up (see `Bone`).
enum Demos {
    static let all: [ExerciseID: Demo] = Dictionary(uniqueKeysWithValues: ExerciseID.allCases.map { ($0, make($0)) })

    static func of(_ id: ExerciseID) -> Demo {
        guard let demo = all[id] else { preconditionFailure("No demo for \(id)") }
        return demo
    }

    private static func make(_ id: ExerciseID) -> Demo {
        switch id {
        case .legPress: legPress
        case .legExtension: legExtension
        case .legCurl: legCurl
        case .gluteBridge: gluteBridge
        case .backExtension: backExtension
        case .gobletSquat: gobletSquat
        case .dumbbellRDL: romanianDeadlift(barbell: false)
        case .splitSquat: splitSquat
        case .backSquat: backSquat
        case .barbellRDL: romanianDeadlift(barbell: true)
        case .hackSquat: hackSquat
        case .smithSquat: smithSquat
        case .hipAbduction: hipMachine(apart: true)
        case .hipAdduction: hipMachine(apart: false)
        case .calfRaise: calfRaise
        case .cableKickback: cableKickback
        case .floorGluteBridge: floorGluteBridge
        case .plank: plank
        case .deadBug: deadBug
        case .abCrunch: abCrunch
        case .kneeRaise: kneeRaise
        case .chestPress: chestPress
        case .latPulldown: latPulldown
        case .assistedPullUp: assistedPullUp
        case .seatedCableRow: seatedCableRow
        case .machineShoulderPress: machineShoulderPress
        case .tricepsPushdown: tricepsPushdown
        case .cableCurl: cableCurl
        case .dumbbellBench: benchPress(barbell: false)
        case .benchPress: benchPress(barbell: true)
        case .oneArmRow: oneArmRow
        case .dumbbellShoulderPress: dumbbellShoulderPress
        case .lateralRaise: lateralRaise
        case .dumbbellCurl: dumbbellCurl
        case .pushUp: pushUp
        case .barbellRow: barbellRow
        case .pecDeck: pecDeck
        case .cableFly: cableFly
        case .assistedDip: assistedDip
        case .machineRow: machineRow
        case .reverseFly: reverseFly
        case .facePull: facePull
        case .cableLateralRaise: cableLateralRaise
        case .preacherCurl: preacherCurl
        case .overheadExtension: overheadExtension
        }
    }
}

// MARK: - Gym furniture

enum Gym {
    /// Hip height of someone standing.
    static let standingHip = -0.525
    /// Hip height on a machine seat.
    static let seatedHip = -0.31
    /// Legs of someone sitting on a machine, feet on the floor.
    static let seatedLegs = Limb.bones(84, 4)

    /// A machine seat under a hip at height `hipY`: the pan, its post and the base.
    static func seat(hipY: Double = seatedHip, from back: Double = -0.1, to front: Double = 0.2) -> [Prop] {
        let surface = hipY + 0.057
        let middle = (back + front) / 2
        return [
            .rod(.at(middle, surface + 0.04), .at(middle, 0), 0.045),
            .rod(.at(middle - 0.17, -0.012), .at(middle + 0.17, -0.012), 0.024),
            .slab(.at(back, surface + 0.025), .at(front, surface + 0.025)),
        ]
    }

    /// A backrest that follows the back, from the hip up past the shoulders.
    static func backrest(to top: Double = 1.2, from bottom: Double = -0.05) -> Prop {
        .slab(.on(.torso, t: bottom, out: -0.09), .on(.torso, t: top, out: -0.09))
    }

    /// A flat bench whose top is at `top`, from `x0` to `x1`.
    static func bench(top: Double = -0.272, from x0: Double, to x1: Double) -> [Prop] {
        [
            .rod(.at(x0 + 0.07, top + 0.03), .at(x0 + 0.07, 0), 0.03),
            .rod(.at(x1 - 0.07, top + 0.03), .at(x1 - 0.07, 0), 0.03),
            .slab(.at(x0, top + 0.025), .at(x1, top + 0.025)),
        ]
    }

    /// A floor mat.
    static func mat(from x0: Double, to x1: Double) -> Prop {
        .slab(.at(x0, -0.008), .at(x1, -0.008), 0.016)
    }

    /// A cable column at `x`: frame, weight stack and the cable from `hand` through `pulley`.
    static func column(x: Double, pulley: CGPoint, to hand: Anchor = .hand(0), top: Double = -1.24) -> [Prop] {
        let height = 0.6
        return [
            .rod(.at(x - 0.1, 0), .at(x - 0.1, top), 0.024),
            .rod(.at(x + 0.1, 0), .at(x + 0.1, top), 0.024),
            .rod(.at(x - 0.12, top), .at(x + 0.12, top), 0.03),
            .stack(x, height: height),
            Prop(shape: .cable([hand, .at(pulley), .at(pulley.x, top + 0.04), .at(x, top + 0.04), stackTop(x, height: height)]), material: .cable, layer: .back),
        ]
    }

    /// The top of a weight stack's moving plates, where its cable starts.
    static func stackTop(_ x: Double, height: Double = 0.62) -> Anchor {
        .load(CGPoint(x: x, y: -height + 0.01), travel: CGVector(dx: 0, dy: -Prop.stackTravel))
    }

    /// A small pivot dot, where a lever turns.
    static func pivot(_ x: Double, _ y: Double) -> Prop {
        .disc(.at(x, y), 0.016, .metal, layer: .front)
    }

    /// A handle seen end-on, gripped in a hand.
    static func grip(_ index: Int = 0, layer: Prop.Layer = .front) -> Prop {
        .disc(.hand(index), 0.022, .metal, layer: layer)
    }

    /// An upright handle across the forearm's end.
    static func uprightGrip(_ index: Int = 0) -> Prop {
        .rod(.on(.forearm(index), t: 1, out: 0.05), .on(.forearm(index), t: 1, out: -0.05), 0.022, .metal, layer: .front)
    }
}

// MARK: - Legs and glutes

private extension Demos {
    static var legPress: Demo {
        // The sled runs up and away at 42° to the floor.
        let rail = direction(132)
        let hip = CGPoint(x: 0, y: -0.3)
        func pose(_ reach: Double) -> Pose {
            let ankle = hip + rail * reach
            return .side(hip: (hip.x, hip.y), torso: 228, nod: 30, arm: .reach(0.04, -0.25), leg: .reach(ankle.x, ankle.y), foot: 222)
        }
        let under = direction(42) * 0.17
        let railStart = hip + rail * 0.22 + under
        let railEnd = hip + rail * 0.88 + under
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose(0.47), end: pose(0.27),
            props: [
                .rod(.at(railStart), .at(railEnd), 0.034),
                .rod(.at(railEnd.x, railEnd.y), .at(railEnd.x, 0), 0.034),
                .rod(.at(-0.3, -0.012), .at(railEnd.x + 0.06, -0.012), 0.024),
                .rod(.at(-0.04, -0.2), .at(-0.04, 0), 0.045),
                .slab(.at(-0.13, -0.2), .at(0.1, -0.28)),
                Gym.backrest(to: 1.25),
                .rod(.on(.foot(0), t: -1.7, out: -0.06), .on(.foot(0), t: -1.7, out: -0.2), 0.04),
                .disc(.on(.foot(0), t: -0.2, out: -0.15), 0.095, .plate),
                .slab(.on(.foot(0), t: -1.8, out: -0.04), .on(.foot(0), t: 1.6, out: -0.04), 0.035, .frame),
            ]
        )
    }

    static var legExtension: Demo {
        let hip = CGPoint(x: 0, y: Gym.seatedHip)
        let knee = hip + direction(90) * Body.thigh
        let pad = Anchor.on(.shin(0), t: 0.86, out: 0.06)
        func pose(_ shin: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 184, arm: .reach(0.06, -0.27), leg: .bones(90, shin))
        }
        return Demo(
            tempo: .liftFirst, muscles: [.quads],
            start: pose(-6), end: pose(82),
            props: Gym.seat(from: -0.1, to: 0.23) + [
                .slab(.at(-0.09, -0.29), .at(-0.11, -0.72)),
                .stack(-0.42),
                .rod(.at(knee), pad, 0.03),
                .disc(pad, 0.042, layer: .front),
                Gym.pivot(knee.x, knee.y),
            ]
        )
    }

    static var legCurl: Demo {
        // Lying face down, head to the right, knees just past the end of the bench.
        let hip = CGPoint(x: 0, y: -0.42)
        let knee = hip + direction(-88) * Body.thigh
        let pad = Anchor.on(.shin(0), t: 0.85, out: -0.058)
        func pose(_ shin: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 92, arm: .bones(56, 92), leg: .bones(-88, shin))
        }
        return Demo(
            tempo: .liftFirst, muscles: [.hamstrings],
            start: pose(-92), end: pose(-198),
            props: Gym.bench(top: -0.36, from: -0.2, to: 0.66) + [
                .rod(.at(knee), pad, 0.03),
                .disc(pad, 0.04, layer: .front),
                Gym.pivot(knee.x, knee.y),
            ]
        )
    }

    static var gluteBridge: Demo {
        // Shoulders rest on the bench edge; the hips swing up around them.
        let shoulders = CGPoint(x: -0.27, y: -0.31)
        func pose(_ torso: Double, nod: Double) -> Pose {
            let hip = shoulders - direction(torso) * (Body.lowerBack + Body.upperBack)
            return .side(hip: (hip.x, hip.y), torso: torso, nod: nod, arm: .reach(.body(t: 0.08, out: 0.12)), leg: .reach(0.36, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.glutes, .hamstrings],
            start: pose(-122, nod: 10), end: pose(-90, nod: 35),
            props: Gym.bench(top: -0.255, from: -0.62, to: -0.2) + [
                .disc(.on(.torso, t: 0.05, out: 0.1), 0.048, layer: .front),
            ]
        )
    }

    static var backExtension: Demo {
        // A 45° bench: legs locked, the hips on the pad, the body hinging over it.
        let hip = (0.0, -0.6)
        func pose(_ torso: Double) -> Pose {
            .side(hip: hip, torso: torso, arm: .reach(.body(t: 0.85, out: 0.07)), leg: .bones(-45, -45))
        }
        return Demo(
            tempo: .liftFirst, muscles: [.lowerBack, .glutes],
            start: pose(52), end: pose(135),
            props: [
                .rod(.at(0.03, -0.5), .at(-0.06, 0), 0.034),
                .rod(.at(-0.3, -0.2), .at(-0.34, 0), 0.034),
                .rod(.at(-0.42, -0.012), .at(0.12, -0.012), 0.024),
                .slab(.on(.foot(0), t: -0.4, out: -0.035), .on(.foot(0), t: 1.4, out: -0.035), 0.03, .frame),
                .disc(.on(.thigh(0), t: 0.14, out: 0.08), 0.05, layer: .front),
                .disc(.on(.shin(0), t: 0.8, out: -0.058), 0.034, layer: .front),
            ]
        )
    }

    static var gobletSquat: Demo {
        func pose(_ hip: (Double, Double), _ torso: Double) -> Pose {
            .side(hip: hip, torso: torso, arm: .reach(.body(t: 0.88, out: 0.14)), leg: .reach(0.0, -0.035), foot: 90)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose((-0.02, -0.522), 180), end: pose((-0.15, -0.3), 150),
            props: [.dumbbell(.hand(0), along: .angle(0))]
        )
    }

    static func romanianDeadlift(barbell: Bool) -> Demo {
        func pose(_ hip: (Double, Double), _ torso: Double) -> Pose {
            .side(hip: hip, torso: torso, arm: .bones(0, 0), leg: .reach(0.0, -0.035), foot: 90)
        }
        let weights: [Prop] = barbell
            ? [.barbell(.hand(0))]
            : [.dumbbell(.hand(1), layer: .far), .dumbbell(.hand(0))]
        return Demo(
            tempo: .lowerFirst, muscles: [.hamstrings, .glutes],
            start: pose((-0.02, -0.522), 180), end: pose((-0.15, -0.49), 106),
            props: weights
        )
    }

    static var splitSquat: Demo {
        // The near leg is in front, the far one behind on its toes.
        func pose(_ hip: (Double, Double)) -> Pose {
            .side(hip: hip, torso: 180, arm: .bones(2, 0), leg: .reach(0.18, -0.035), farLeg: .reach(-0.28, -0.08), foot: 90, farFoot: 40)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose((-0.03, -0.47)), end: pose((-0.05, -0.27)),
            props: [.dumbbell(.hand(1), layer: .far), .dumbbell(.hand(0))]
        )
    }

    static var backSquat: Demo {
        func pose(_ hip: (Double, Double), _ torso: Double) -> Pose {
            .side(hip: hip, torso: torso, arm: .reach(.body(t: 0.95, out: -0.075), bend: -1), leg: .reach(0.02, -0.035), foot: 90)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose((-0.02, -0.522), 178), end: pose((-0.17, -0.3), 140),
            props: [
                .rod(.at(-0.44, 0), .at(-0.44, -1.15), 0.034),
                .rod(.at(0.36, 0), .at(0.36, -1.15), 0.034),
                .rod(.at(-0.5, -0.45), .at(0.42, -0.45), 0.02),
                .rod(.at(0.36, -0.86), .at(0.29, -0.86), 0.02, .metal),
                .barbell(.on(.torso, t: 0.92, out: -0.08), radius: 0.07),
            ]
        )
    }

    static var hackSquat: Demo {
        // The back pad slides along a rail leaning back 20°.
        let slide = direction(20)
        let top = CGPoint(x: 0, y: -0.56)
        let bottom = top + slide * 0.22
        let back = CGVector(dx: -0.94, dy: 0.342)
        func pose(_ hip: CGPoint) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 200, arm: .reach(.body(t: 1.0, out: 0.09)), leg: .reach(0.17, -0.12), foot: 75)
        }
        let railLow = bottom + back * 0.14 + slide * 0.12
        let railHigh = top + back * 0.14 - slide * 0.45
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose(top), end: pose(bottom),
            props: [
                .rod(.at(railLow), .at(railHigh), 0.034),
                .rod(.at(railLow.x, railLow.y), .at(railLow.x, 0), 0.034),
                .rod(.at(0.24, -0.1), .at(0.26, 0), 0.03),
                .rod(.at(railLow.x - 0.12, -0.012), .at(0.36, -0.012), 0.024),
                .disc(.on(.torso, t: 0.9, out: -0.2), 0.09, .plate),
                .slab(.on(.foot(0), t: -0.8, out: -0.035), .on(.foot(0), t: 1.5, out: -0.035), 0.03, .frame),
                Gym.backrest(to: 1.08),
                .disc(.on(.torso, t: 1.12, out: 0.01), 0.042, layer: .front),
            ]
        )
    }

    static var smithSquat: Demo {
        // Feet a little forward so the bar can travel straight down its rails.
        func pose(_ hip: (Double, Double), _ torso: Double) -> Pose {
            .side(hip: hip, torso: torso, arm: .reach(.body(t: 0.95, out: -0.075), bend: -1), leg: .reach(0.1, -0.035), foot: 90)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.quads, .glutes],
            start: pose((0.0, -0.522), 180), end: pose((-0.1, -0.3), 160),
            props: [
                .rod(.at(-0.07, 0), .at(-0.07, -1.18), 0.016, .metal),
                .rod(.at(-0.2, -1.18), .at(0.06, -1.18), 0.034),
                .rod(.at(-0.2, -1.18), .at(-0.2, 0), 0.034),
                .barbell(.on(.torso, t: 0.92, out: -0.08), radius: 0.07),
            ]
        )
    }

    /// The seated hip machine from the front: knees pushed apart, or squeezed together.
    static func hipMachine(apart: Bool) -> Demo {
        func pose(_ thigh: Double, _ shin: Double) -> Pose {
            .front(hip: (0, -0.33), arm: .reach(0.24, -0.33), leg: .bones(Bone(thigh, length: 0.46), Bone(shin, length: 0.7)))
        }
        let together = pose(7, 0), wide = pose(36, 12)
        let side = apart ? 0.055 : -0.055
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: apart ? [.glutes] : [.adductors],
            start: apart ? together : wide, end: apart ? wide : together,
            props: [
                .slab(.at(0, -0.3), .at(0, -0.84), 0.3),
                .rod(.at(0, -0.24), .at(0, 0), 0.045),
                .slab(.at(-0.2, -0.255), .at(0.2, -0.255)),
                .rod(.at(0, -0.07), .on(.thigh(0), t: 0.95, out: side), 0.026),
                .rod(.at(0, -0.07), .on(.thigh(1), t: 0.95, out: side), 0.026),
                .disc(.on(.thigh(0), t: 0.95, out: side), 0.045, layer: .front),
                .disc(.on(.thigh(1), t: 0.95, out: side), 0.045, layer: .front),
            ]
        )
    }

    static var calfRaise: Demo {
        // The balls of the feet stay on the block's edge; the body rises over them.
        let toe = CGPoint(x: 0.07, y: -0.1)
        func pose(_ foot: Double) -> Pose {
            let ankle = toe - direction(foot) * Body.toes
            let hip = ankle - CGVector(dx: 0, dy: Body.thigh + Body.shin)
            return .side(hip: (hip.x, hip.y), torso: 180, arm: .reach(.body(t: 1.0, out: 0.11)), leg: .bones(0, 0), foot: foot)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.calves],
            start: pose(112), end: pose(48),
            props: [
                .stack(-0.42, height: 0.55),
                .rod(.on(.torso, t: 1.1, out: 0), .at(-0.36, -1.0), 0.03),
                .rod(.at(-0.3, -1.05), .at(-0.3, 0), 0.034),
                .slab(.at(0.0, -0.05), .at(0.15, -0.05), 0.1, .frame),
                .disc(.on(.torso, t: 1.1, out: 0), 0.042, layer: .front),
            ]
        )
    }

    static var cableKickback: Demo {
        func pose(_ thigh: Double, _ shin: Double) -> Pose {
            .side(hip: (-0.02, -0.52), torso: 162, arm: .reach(0.3, -0.74), leg: .bones(thigh, shin), farLeg: .reach(0.0, -0.035), foot: nil, farFoot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.glutes],
            start: pose(4, -2), end: pose(-38, -46),
            props: Gym.column(x: 0.48, pulley: CGPoint(x: 0.34, y: -0.07), to: .on(.shin(0), t: 0.95)) + [
                .rod(.at(0.36, -0.68), .at(0.36, -0.8), 0.024, .metal),
            ]
        )
    }

    static var floorGluteBridge: Demo {
        let shoulders = CGPoint(x: -0.32, y: -0.065)
        func pose(_ torso: Double, nod: Double) -> Pose {
            let hip = shoulders - direction(torso) * (Body.lowerBack + Body.upperBack)
            return .side(hip: (hip.x, hip.y), torso: torso, nod: nod, arm: .bones(88, 90), leg: .reach(0.3, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.glutes, .hamstrings],
            start: pose(-90, nod: 0), end: pose(-58, nod: 32),
            props: [Gym.mat(from: -0.55, to: 0.48)]
        )
    }
}

// MARK: - Core

private extension Demos {
    static var plank: Demo {
        // Forearms on the floor, one straight line from the shoulders to the heels.
        let shoulder = CGPoint(x: 0.24, y: -0.215)
        func pose(_ sag: Double) -> Pose {
            let torso = 101.2 - sag
            let hip = shoulder - direction(torso) * (Body.lowerBack + Body.upperBack)
            return .side(hip: (hip.x, hip.y), torso: torso, arm: .bones(0, 90), leg: .reach(-0.54, -0.06), foot: 50)
        }
        return Demo(
            tempo: .hold, muscles: [.abs],
            start: pose(0), end: pose(1.2),
            props: [Gym.mat(from: -0.68, to: 0.56)]
        )
    }

    static var deadBug: Demo {
        // On the back, head to the left: arms to the ceiling, knees over the hips.
        func pose(arm: Limb = .bones(180, 180), farArm: Limb = .bones(180, 180), leg: Limb = .bones(180, 90), farLeg: Limb = .bones(180, 90)) -> Pose {
            .side(hip: (0, -0.066), torso: -90, arm: arm, farArm: farArm, leg: leg, farLeg: farLeg)
        }
        let reach = Limb.bones(262, 266), stretch = Limb.bones(108, 98)
        return Demo(
            tempo: .lowerFirst, muscles: [.abs],
            start: pose(), end: pose(arm: reach, farLeg: stretch), alternate: pose(farArm: reach, leg: stretch),
            props: [Gym.mat(from: -0.68, to: 0.6)]
        )
    }

    static var abCrunch: Demo {
        func pose(_ torso: Double, spine: Double) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: torso, spine: spine, nod: spine * 0.3, arm: .reach(.body(t: 1.0, out: 0.08)), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.abs],
            start: pose(184, spine: 0), end: pose(176, spine: 48),
            props: Gym.seat(from: -0.1, to: 0.22) + [
                .stack(-0.42),
                .slab(.at(-0.09, -0.29), .at(-0.1, -0.52)),
                .rod(.at(-0.14, -0.5), .hand(0), 0.03),
                .disc(.on(.shin(0), t: 0.85, out: 0.055), 0.034, layer: .front),
            ]
        )
    }

    static var kneeRaise: Demo {
        // Hanging on the forearm pads of a captain's chair, back against the pad.
        func pose(_ thigh: Double, tilt: Double) -> Pose {
            .side(hip: (0, -0.86), torso: 180 + tilt, spine: -tilt, arm: .bones(0, 90), leg: .bones(thigh, 4))
        }
        return Demo(
            tempo: .liftFirst, muscles: [.abs],
            start: pose(2, tilt: 0), end: pose(100, tilt: 8),
            props: [
                .rod(.at(-0.12, -1.3), .at(-0.12, 0), 0.034),
                .rod(.at(-0.12, -0.99), .at(0.24, -0.99), 0.028),
                .rod(.at(-0.3, -0.012), .at(0.1, -0.012), 0.024),
                .slab(.at(-0.075, -0.92), .at(-0.075, -1.24)),
                .slab(.on(.forearm(0), t: -0.1, out: -0.045), .on(.forearm(0), t: 0.95, out: -0.045), 0.045),
                Gym.grip(),
            ]
        )
    }
}
