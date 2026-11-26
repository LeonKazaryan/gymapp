import CoreGraphics

// Machines and moves added from a real gym program: pullovers, flys, the upright row and the
// leg machines beginners meet on leg day.

extension Demos {
    static var plateChestPress: Demo {
        // Like the stack machine, but each arm swings on its own lever loaded with plates.
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: 188, arm: .reach(hand.0, hand.1), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.chest, .triceps],
            start: pose((0.14, -0.57)), end: pose((0.32, -0.62)),
            props: Gym.seat() + [
                // The lever runs from a low pivot behind the seat to the plates under the handle.
                .rod(.at(-0.16, -0.16), .on(.forearm(0), t: 1, out: -0.17), 0.034),
                .rod(.on(.forearm(0), t: 1, out: -0.17), .on(.forearm(0), t: 1, out: 0), 0.03),
                Gym.pivot(-0.16, -0.16),
                .disc(.on(.forearm(0), t: 1, out: -0.17), 0.085, .plate),
                Gym.backrest(to: 1.25),
                Gym.uprightGrip(),
            ]
        )
    }

    static var dumbbellFly: Demo {
        // Seen from above: on the back, head to the left, arms opening out to the sides.
        func pose(near: (CGVector, CGVector), far: (CGVector, CGVector)) -> Pose {
            Pose(
                hip: CGPoint(x: 0, y: -0.5), torso: Bone(-90),
                arms: [.flat(near.0, near.1), .flat(far.0, far.1)],
                legs: [.bones(Bone(82, length: 0.7), Bone(95, length: 0.4)), .bones(Bone(98, length: 0.7), Bone(85, length: 0.4))]
            )
        }
        let together = (CGVector(dx: 0.05, dy: 0.18), CGVector(dx: 0.03, dy: 0.12))
        let open = (CGVector(dx: 0.08, dy: -0.95), CGVector(dx: 0.12, dy: -0.92))
        func mirrored(_ arm: (CGVector, CGVector)) -> (CGVector, CGVector) {
            (CGVector(dx: arm.0.dx, dy: -arm.0.dy), CGVector(dx: arm.1.dx, dy: -arm.1.dy))
        }
        var demo = Demo(
            camera: .front, tempo: .lowerFirst, muscles: [.chest],
            start: pose(near: together, far: mirrored(together)), end: pose(near: open, far: mirrored(open)),
            props: [
                .slab(.at(-0.62, -0.5), .at(0.14, -0.5), 0.26),
                .dumbbell(.hand(0), along: .angle(90)),
                .dumbbell(.hand(1), along: .angle(90)),
            ]
        )
        demo.showsFloor = false
        return demo
    }

    static var machinePullover: Demo {
        // Elbows on the pads, the arms swing from overhead down in front of the body. The
        // machine turns around the shoulder.
        let hip = CGPoint(x: 0, y: Gym.seatedHip)
        let shoulder = hip + direction(184) * (Body.lowerBack + Body.upperBack)
        func pose(_ upper: Double, _ lower: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 184, arm: .bones(upper, lower), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.lats, .chest],
            start: pose(198, 140), end: pose(12, 96),
            props: Gym.seat() + [
                .stack(-0.46),
                .rod(.at(shoulder), .on(.upperArm(0), t: 1.05, out: -0.06), 0.034),
                .disc(.on(.upperArm(0), t: 0.95, out: -0.05), 0.036, layer: .front),
                Gym.pivot(shoulder.x, shoulder.y),
                Gym.backrest(to: 1.25),
                .slab(.on(.thigh(0), t: 0.1, out: 0.06), .on(.thigh(0), t: 0.45, out: 0.06), 0.03, .frame, layer: .front),
                Gym.grip(),
            ]
        )
    }

    static var dumbbellPullover: Demo {
        // On the back, head to the left; one dumbbell travels from over the chest to behind the head.
        func pose(_ upper: Double, _ lower: Double) -> Pose {
            .side(hip: (0, -0.33), torso: -90, arm: .bones(upper, lower), leg: .reach(0.4, -0.035), foot: 90)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.lats, .chest],
            start: pose(180, 186), end: pose(256, 266),
            props: Gym.bench(from: -0.64, to: 0.1) + [.dumbbell(.hand(0), along: .bone(.forearm(0)))]
        )
    }

    static var uprightRow: Demo {
        // From the front: a wide grip, the elbows lead the bar up to the chest.
        func pose(_ hand: (Double, Double)) -> Pose {
            .front(hip: (0, Gym.standingHip), arm: .reach(.point(CGPoint(x: hand.0, y: hand.1)), bend: -1), leg: .bones(3, 1))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.shoulders, .upperBack],
            start: pose((0.2, -0.47)), end: pose((0.21, -0.65)),
            props: [.rod(.hand(1), .hand(0), 0.022, .metal, layer: .front)]
        )
    }

    static var tricepsMachine: Demo {
        // The upper arms rest on a sloped pad; the forearms straighten forward and down.
        let hip = CGPoint(x: 0, y: Gym.seatedHip)
        let shoulder = hip + direction(176) * (Body.lowerBack + Body.upperBack)
        let elbow = shoulder + direction(62) * Body.upperArm
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 176, arm: .bones(62, forearm), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.triceps],
            start: pose(172), end: pose(66),
            props: Gym.seat() + [
                .rod(.at(0.17, -0.44), .at(0.17, 0), 0.034),
                .slab(.on(.upperArm(0), t: -0.05, out: -0.06), .on(.upperArm(0), t: 1.15, out: -0.06), 0.06, layer: .mid),
                .rod(.at(elbow), .hand(0), 0.026),
                Gym.pivot(elbow.x, elbow.y),
                Gym.grip(),
            ]
        )
    }

    static var seatedLegCurl: Demo {
        // Legs out straight on a roller, a pad holding the thighs; the heels pull under the seat.
        let hip = CGPoint(x: 0, y: -0.36)
        let knee = hip + direction(88) * Body.thigh
        let roller = Anchor.on(.shin(0), t: 0.85, out: -0.06)
        func pose(_ shin: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 192, arm: .reach(0.08, -0.33), leg: .bones(88, shin))
        }
        return Demo(
            tempo: .liftFirst, muscles: [.hamstrings],
            start: pose(80), end: pose(-22),
            props: Gym.seat(hipY: hip.y, from: -0.1, to: 0.24) + [
                .stack(-0.44),
                .slab(.on(.torso, t: -0.05, out: -0.09), .on(.torso, t: 1.2, out: -0.09)),
                .rod(.at(knee), roller, 0.03),
                .disc(roller, 0.04, layer: .front),
                .disc(.on(.thigh(0), t: 0.82, out: 0.075), 0.04, layer: .front),
                Gym.pivot(knee.x, knee.y),
            ]
        )
    }

    static var standingLegCurl: Demo {
        // Standing on one leg, the other knee against a pad; the heel kicks up behind.
        let hip = CGPoint(x: -0.02, y: -0.52)
        let knee = hip + direction(4) * Body.thigh
        let roller = Anchor.on(.shin(0), t: 0.85, out: -0.06)
        func pose(_ shin: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 168, arm: .reach(0.3, -0.8), leg: .bones(4, shin), farLeg: .reach(-0.02, -0.035), foot: nil, farFoot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.hamstrings],
            start: pose(-2), end: pose(-112),
            props: [
                .stack(0.52, height: 0.55),
                .rod(.at(0.38, 0), .at(0.38, -1.0), 0.034),
                .rod(.at(0.38, -0.8), .at(0.29, -0.8), 0.024, .metal),
                .rod(.at(0.38, -0.3), .at(0.1, -0.3), 0.03),
                .disc(.on(.thigh(0), t: 0.88, out: 0.07), 0.04, layer: .front),
                .rod(.at(knee), roller, 0.03),
                .disc(roller, 0.04, layer: .front),
                Gym.pivot(knee.x, knee.y),
            ]
        )
    }

    static var seatedCalfRaise: Demo {
        // Seated, a pad on the knees, the balls of the feet on a block: the heels rise and
        // lift the knees with them.
        let toe = CGPoint(x: 0.27, y: -0.1)
        func pose(_ foot: Double) -> Pose {
            let ankle = toe - direction(foot) * Body.toes
            return .side(hip: (0, -0.34), torso: 174, arm: .reach(0.2, -0.43), leg: .reach(ankle.x, ankle.y), foot: foot)
        }
        let pad = Anchor.on(.thigh(0), t: 0.9, out: 0.065)
        return Demo(
            tempo: .liftFirst, muscles: [.calves],
            start: pose(112), end: pose(48),
            props: Gym.seat(hipY: -0.34, from: -0.12, to: 0.14) + [
                .slab(.at(0.2, -0.05), .at(0.34, -0.05), 0.1, .frame),
                .rod(pad, .at(0.52, -0.46), 0.03),
                .disc(.at(0.52, -0.46), 0.09, .plate),
                .disc(pad, 0.04, layer: .front),
            ]
        )
    }
}
