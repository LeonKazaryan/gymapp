import CoreGraphics

// MARK: - Chest and shoulders

extension Demos {
    static var chestPress: Demo {
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: 186, arm: .reach(hand.0, hand.1), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.chest, .triceps],
            start: pose((0.1, -0.585)), end: pose((0.33, -0.6)),
            props: Gym.seat() + [
                .stack(-0.44),
                .rod(.at(-0.27, 0), .at(-0.27, -1.04), 0.034),
                .rod(.at(-0.29, -1.02), .at(0.0, -1.02), 0.034),
                .rod(.at(0.0, -1.02), .on(.forearm(0), t: 1, out: 0.05), 0.03),
                Gym.backrest(to: 1.25),
                Gym.uprightGrip(),
            ]
        )
    }

    static var machineShoulderPress: Demo {
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: 184, arm: .reach(hand.0, hand.1), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.shoulders, .triceps],
            start: pose((0.11, -0.64)), end: pose((0.04, -0.96)),
            props: Gym.seat() + [
                .stack(-0.46),
                .rod(.at(-0.3, -0.56), .hand(0), 0.03),
                Gym.pivot(-0.3, -0.56),
                Gym.backrest(to: 1.3),
                Gym.grip(),
            ]
        )
    }

    static func benchPress(barbell: Bool) -> Demo {
        // On the back, head to the left, feet flat on the floor.
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (0, -0.33), torso: -90, arm: .reach(hand.0, hand.1), leg: .reach(0.4, -0.035), foot: 90)
        }
        let start = barbell ? (-0.29, -0.69) : (-0.27, -0.69)
        let end = barbell ? (-0.19, -0.43) : (-0.25, -0.42)
        var props = Gym.bench(from: -0.64, to: 0.1)
        if barbell {
            props += [
                .rod(.at(-0.5, 0), .at(-0.5, -0.8), 0.034),
                .rod(.at(-0.5, -0.74), .at(-0.43, -0.74), 0.02, .metal),
                .barbell(.hand(0)),
            ]
        } else {
            props += [.dumbbell(.hand(1), layer: .far), .dumbbell(.hand(0))]
        }
        return Demo(tempo: .lowerFirst, muscles: [.chest, .triceps], start: pose(start), end: pose(end), props: props)
    }

    static var dumbbellShoulderPress: Demo {
        func pose(_ hand: (Double, Double)) -> Pose {
            .front(hip: (0, -0.33), arm: .reach(hand.0, hand.1), leg: .bones(Bone(12, length: 0.4), Bone(4, length: 0.85)))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.shoulders, .triceps],
            start: pose((0.25, -0.76)), end: pose((0.15, -0.99)),
            props: [
                .slab(.at(0, -0.3), .at(0, -0.86), 0.26),
                .slab(.at(-0.2, -0.255), .at(0.2, -0.255)),
                .rod(.at(0, -0.24), .at(0, 0), 0.045),
                .dumbbell(.hand(0), along: .angle(90)),
                .dumbbell(.hand(1), along: .angle(90)),
            ]
        )
    }

    static var lateralRaise: Demo {
        func pose(_ arm: Limb) -> Pose {
            .front(hip: (0, Gym.standingHip), arm: arm, leg: .bones(3, 1))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.shoulders],
            start: pose(.bones(8, 5)), end: pose(.bones(84, 78)),
            props: [.dumbbell(.hand(0)), .dumbbell(.hand(1))]
        )
    }

    static var cableLateralRaise: Demo {
        // The right arm works; the cable comes across the body from a low pulley on the left.
        func pose(_ arm: Limb) -> Pose {
            .front(hip: (0, Gym.standingHip), arm: arm, leftArm: .reach(-0.42, -0.78), leg: .bones(3, 1))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.shoulders],
            start: pose(.bones(-12, -14)), end: pose(.bones(84, 78)),
            props: [
                .rod(.at(-0.5, 0), .at(-0.5, -1.2), 0.034),
                .rod(.at(-0.5, -0.07), .at(-0.4, -0.07), 0.024),
                Prop(shape: .cable([.hand(0), .at(-0.4, -0.07)]), material: .cable, layer: .front),
                Gym.grip(),
            ]
        )
    }

    static var pushUp: Demo {
        // The body pivots on the toes as one straight plank.
        let ankle = CGPoint(x: -0.632, y: -0.08)
        func pose(_ rise: Double) -> Pose {
            let length = Body.thigh + Body.shin + Body.lowerBack + Body.upperBack
            let angle = asin((rise - 0.08) / length)
            let torso = 90 + angle * 180 / .pi
            let hip = ankle + direction(torso) * (Body.thigh + Body.shin)
            return .side(hip: (hip.x, hip.y), torso: torso, arm: .reach(0.1, -0.03), leg: .reach(ankle.x, ankle.y), foot: 53)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.chest, .triceps, .abs],
            start: pose(0.39), end: pose(0.15),
            props: [Gym.mat(from: -0.78, to: 0.3)]
        )
    }

    static var pecDeck: Demo {
        // From the front: forearms upright on the pads, swinging in until they meet.
        func pose(_ upper: Double) -> Pose {
            .front(hip: (0, -0.33), arm: .flat(CGVector(dx: upper, dy: 0), CGVector(dx: 0.05, dy: -1)), leg: .bones(Bone(12, length: 0.4), Bone(4, length: 0.85)))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.chest],
            start: pose(1), end: pose(-0.33),
            props: [
                .slab(.at(0, -0.3), .at(0, -0.9), 0.3),
                .slab(.at(-0.2, -0.255), .at(0.2, -0.255)),
                .rod(.at(0, -0.24), .at(0, 0), 0.045),
                .rod(.at(-0.32, -1.08), .at(0.32, -1.08), 0.034),
                .slab(.on(.forearm(0), t: 0.05, out: 0.035), .on(.forearm(0), t: 0.95, out: 0.035), 0.05, layer: .front),
                .slab(.on(.forearm(1), t: 0.05, out: 0.035), .on(.forearm(1), t: 0.95, out: 0.035), 0.05, layer: .front),
            ]
        )
    }

    static var cableFly: Demo {
        // Between two high pulleys, the hands sweep down and in to meet in front of the belly.
        func pose(_ upper: CGVector, _ lower: CGVector) -> Pose {
            .front(hip: (0, Gym.standingHip), arm: .flat(upper, lower), leg: .bones(4, 1))
        }
        let pulley = CGPoint(x: 0.68, y: -1.16)
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.chest],
            start: pose(CGVector(dx: 0.86, dy: -0.42), CGVector(dx: 0.8, dy: -0.3)),
            end: pose(CGVector(dx: -0.25, dy: 0.55), CGVector(dx: -0.22, dy: 0.36)),
            props: [
                .rod(.at(0.78, 0), .at(0.78, -1.24), 0.04),
                .rod(.at(-0.78, 0), .at(-0.78, -1.24), 0.04),
                .rod(.at(0.78, -1.16), .at(0.66, -1.16), 0.024),
                .rod(.at(-0.78, -1.16), .at(-0.66, -1.16), 0.024),
                .cable(.hand(0), .at(pulley)),
                .cable(.hand(1), .at(-pulley.x, pulley.y)),
                Gym.grip(0), Gym.grip(1),
            ]
        )
    }

    static var assistedDip: Demo {
        // Kneeling on the assist pad, hands on the dip bars, which stay put.
        let hands = CGPoint(x: 0.03, y: -0.76)
        func pose(_ shoulderDrop: Double, _ torso: Double) -> Pose {
            let shoulders = CGPoint(x: hands.x - shoulderDrop * 0.15, y: hands.y - Body.upperArm - Body.forearm + shoulderDrop)
            let hip = shoulders - direction(torso) * (Body.lowerBack + Body.upperBack)
            return .side(hip: (hip.x, hip.y), torso: torso, arm: .reach(hands.x, hands.y), leg: .bones(4, -86))
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.chest, .triceps],
            start: pose(0, 178), end: pose(0.19, 162),
            props: [
                .rod(.at(0.2, -0.76), .at(0.2, 0), 0.034),
                .rod(.at(-0.06, -0.76), .at(0.2, -0.76), 0.024, .metal),
                .rod(.at(-0.2, -0.22), .on(.shin(0), t: 0.4, out: 0.09), 0.03),
                Gym.pivot(-0.2, -0.22),
                .slab(.on(.shin(0), t: -0.12, out: 0.06), .on(.shin(0), t: 0.95, out: 0.06), 0.045),
            ]
        )
    }

    static var reverseFly: Demo {
        // From behind: arms swing out from in front of the chest to a T.
        func pose(_ upper: CGVector, _ lower: CGVector) -> Pose {
            .front(hip: (0, -0.33), arm: .flat(upper, lower), leg: .bones(Bone(10, length: 0.4), Bone(3, length: 0.85)))
        }
        return Demo(
            camera: .back, tempo: .liftFirst, muscles: [.rearDelts, .upperBack],
            start: pose(CGVector(dx: -0.25, dy: 0.05), CGVector(dx: -0.3, dy: 0.02)),
            end: pose(CGVector(dx: 1, dy: 0.04), CGVector(dx: 0.99, dy: 0.06)),
            props: [
                .slab(.at(-0.2, -0.255), .at(0.2, -0.255)),
                .rod(.at(0, -0.24), .at(0, 0), 0.045),
                .rod(.at(-0.32, -1.08), .at(0.32, -1.08), 0.034),
                .rod(.at(0.06, -1.06), .on(.forearm(0), t: 1, out: 0.05), 0.028),
                .rod(.at(-0.06, -1.06), .on(.forearm(1), t: 1, out: 0.05), 0.028),
                Gym.uprightGrip(0), Gym.uprightGrip(1),
            ]
        )
    }
}

// MARK: - Back

extension Demos {
    static var latPulldown: Demo {
        // From the front: the bar comes from overhead down to the top of the chest.
        let top = -0.96, travel = 0.31
        func pose(_ y: Double) -> Pose {
            .front(hip: (0, -0.33), arm: .reach(0.27, y), leg: .bones(Bone(10, length: 0.4), Bone(2, length: 0.85)))
        }
        func bar(_ x: Double) -> Anchor { .load(CGPoint(x: x, y: top), travel: CGVector(dx: 0, dy: travel)) }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.lats, .biceps],
            start: pose(top), end: pose(top + travel),
            props: [
                .slab(.at(-0.2, -0.255), .at(0.2, -0.255)),
                .rod(.at(0, -0.24), .at(0, 0), 0.045),
                .rod(.at(-0.36, -1.26), .at(0.36, -1.26), 0.034),
                .cable(bar(0), .at(0, -1.22)),
                .disc(.at(0, -1.22), 0.028, .frame),
                .rod(bar(-0.38), bar(0.38), 0.02, .metal, layer: .front),
                .slab(.at(-0.21, -0.275), .at(0.21, -0.275), 0.05, layer: .front),
            ]
        )
    }

    static var assistedPullUp: Demo {
        // Kneeling on the counterweight pad; it lifts the body towards the fixed handles.
        let hands = CGPoint(x: 0.21, y: -1.2)
        func pose(_ hipY: Double) -> Pose {
            .front(hip: (0, hipY), arm: .reach(hands.x, hands.y), leg: .bones(Bone(3, length: 0.95), Bone(0, length: 0.3)))
        }
        return Demo(
            camera: .front, tempo: .liftFirst, muscles: [.lats, .biceps],
            start: pose(-0.55), end: pose(-0.85),
            props: [
                .rod(.at(-0.45, -1.32), .at(0.45, -1.32), 0.034),
                .rod(.at(hands.x, -1.32), .at(hands.x, -1.2), 0.024, .metal),
                .rod(.at(-hands.x, -1.32), .at(-hands.x, -1.2), 0.024, .metal),
                .rod(.at(0.45, -1.32), .at(0.45, 0), 0.034),
                .rod(.at(-0.45, -1.32), .at(-0.45, 0), 0.034),
                .rod(.at(0, -0.05), .at(0, -0.2), 0.03),
                .slab(.on(.thigh(1), t: 1.12, out: 0.07), .on(.thigh(0), t: 1.12, out: 0.07), 0.055, layer: .front),
            ]
        )
    }

    static var seatedCableRow: Demo {
        func pose(_ torso: Double, _ hand: (Double, Double)) -> Pose {
            .side(hip: (0, -0.25), torso: torso, arm: .reach(hand.0, hand.1), leg: .reach(0.43, -0.15), foot: 175)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.upperBack, .lats],
            start: pose(160, (0.45, -0.42)), end: pose(188, (0.1, -0.38)),
            props: Gym.bench(top: -0.193, from: -0.42, to: 0.22) + Gym.column(x: 0.78, pulley: CGPoint(x: 0.6, y: -0.38)) + [
                .slab(.at(0.48, -0.04), .at(0.48, -0.3), 0.03, .frame),
                Gym.grip(),
            ]
        )
    }

    static var oneArmRow: Demo {
        // One knee and one hand on the bench, the near arm rowing.
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (-0.08, -0.53), torso: 98, arm: .reach(hand.0, hand.1), farArm: .reach(0.25, -0.28), leg: .reach(-0.12, -0.035), farLeg: .bones(0, -90), foot: 90, farFoot: nil)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.lats, .upperBack],
            start: pose((0.22, -0.21)), end: pose((0.0, -0.47)),
            props: Gym.bench(top: -0.25, from: -0.3, to: 0.42) + [.dumbbell(.hand(0))]
        )
    }

    static var barbellRow: Demo {
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (-0.1, -0.47), torso: 135, arm: .reach(hand.0, hand.1), leg: .reach(0.02, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.upperBack, .lats],
            start: pose((0.115, -0.315)), end: pose((0.035, -0.463)),
            props: [.barbell(.hand(0))]
        )
    }

    static var machineRow: Demo {
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: 178, arm: .reach(hand.0, hand.1), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.upperBack, .lats],
            start: pose((0.37, -0.55)), end: pose((0.07, -0.52)),
            props: Gym.seat() + [
                .stack(0.7),
                .rod(.at(0.58, 0), .at(0.58, -1.0), 0.034),
                .rod(.at(0.58, -0.98), .at(0.44, -0.98), 0.034),
                .rod(.at(0.44, -0.98), .on(.forearm(0), t: 1, out: 0.05), 0.03),
                .slab(.at(0.095, -0.4), .at(0.095, -0.66), layer: .mid),
                .rod(.at(0.12, -0.53), .at(0.3, -0.53), 0.03),
                .rod(.at(0.3, -0.53), .at(0.3, 0), 0.034),
                Gym.uprightGrip(),
            ]
        )
    }

    static var facePull: Demo {
        // A rope at face height, pulled apart towards the face with the elbows high.
        func pose(_ hand: (Double, Double)) -> Pose {
            .side(hip: (-0.04, Gym.standingHip), torso: 184, arm: .reach(.point(CGPoint(x: hand.0, y: hand.1)), bend: -1), leg: .reach(0.0, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.rearDelts, .upperBack],
            start: pose((0.29, -0.88)), end: pose((0.07, -0.92)),
            props: Gym.column(x: 0.66, pulley: CGPoint(x: 0.5, y: -0.92)) + [Gym.grip()]
        )
    }
}

// MARK: - Arms

extension Demos {
    static var tricepsPushdown: Demo {
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (-0.04, Gym.standingHip), torso: 172, arm: .bones(8, forearm), leg: .reach(0.0, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.triceps],
            start: pose(96), end: pose(6),
            props: Gym.column(x: 0.5, pulley: CGPoint(x: 0.32, y: -1.12)) + [
                .rod(.on(.forearm(0), t: 1, out: 0.045), .on(.forearm(0), t: 1, out: -0.045), 0.022, .metal, layer: .front),
            ]
        )
    }

    static var cableCurl: Demo {
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (-0.04, Gym.standingHip), torso: 180, arm: .bones(-2, forearm), leg: .reach(-0.02, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.biceps],
            start: pose(6), end: pose(146),
            props: Gym.column(x: 0.5, pulley: CGPoint(x: 0.32, y: -0.08)) + [Gym.grip()]
        )
    }

    static var dumbbellCurl: Demo {
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (-0.02, Gym.standingHip), torso: 180, arm: .bones(-2, forearm), leg: .reach(0.0, -0.035), foot: 90)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.biceps],
            start: pose(4), end: pose(146),
            props: [.dumbbell(.hand(1), layer: .far), .dumbbell(.hand(0))]
        )
    }

    static var preacherCurl: Demo {
        let hip = CGPoint(x: 0, y: Gym.seatedHip)
        let shoulder = hip + direction(172) * (Body.lowerBack + Body.upperBack)
        let elbow = shoulder + direction(42) * Body.upperArm
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (hip.x, hip.y), torso: 172, arm: .bones(42, forearm), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .liftFirst, muscles: [.biceps],
            start: pose(52), end: pose(168),
            props: Gym.seat() + [
                .rod(.at(0.13, -0.42), .at(0.13, 0), 0.034),
                .slab(.on(.upperArm(0), t: -0.05, out: -0.06), .on(.upperArm(0), t: 1.15, out: -0.06), 0.06, layer: .mid),
                .rod(.at(elbow), .hand(0), 0.026),
                Gym.pivot(elbow.x, elbow.y),
                Gym.grip(),
            ]
        )
    }

    static var overheadExtension: Demo {
        // Seated, one dumbbell in both hands, lowered behind the head with the elbows up.
        func pose(_ forearm: Double) -> Pose {
            .side(hip: (0, Gym.seatedHip), torso: 182, arm: .bones(176, forearm), leg: Gym.seatedLegs)
        }
        return Demo(
            tempo: .lowerFirst, muscles: [.triceps],
            start: pose(182), end: pose(290),
            props: Gym.seat() + [
                Gym.backrest(to: 0.85),
                .dumbbell(.hand(0), along: .bone(.forearm(0))),
            ]
        )
    }
}
