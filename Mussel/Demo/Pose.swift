import CoreGraphics

/// How a demo looks at the figure.
enum Camera: Sendable {
    /// From the figure's left: it faces right. Limb 0 is the near one.
    case side
    /// From the front. Limb 0 is on the screen's right.
    case front
    /// From behind. Arms reaching forward disappear behind the back.
    case back
}

/// A bone's direction in degrees: 0 points straight down, 90 forward (right on screen from
/// the side), 180 up, −90 back. `length` shortens a bone that points at the camera.
struct Bone: Sendable {
    var angle: Double
    var length: Double = 1

    init(_ angle: Double, length: Double = 1) {
        self.angle = angle
        self.length = length
    }
}

/// Where a hand or a foot goes.
enum Target: Sendable {
    /// A fixed point in the scene: a handle, a spot on the floor.
    case point(CGPoint)
    /// A spot on the torso, `t` from the hip (0) to the shoulders (1) and `out` in front of it.
    /// Hands holding something against the body move with it.
    case body(t: Double, out: Double)
}

enum Limb: Sendable {
    /// Two bones set by direction, from the body out.
    case bones(Bone, Bone)
    /// The end of the limb at a target. The middle joint bends the natural way (knees forward,
    /// elbows back); `bend: -1` bends it the other way.
    case reach(Target, bend: Double = 1)
    /// Two bones as they look on screen, in bone lengths, blended in a straight line. For
    /// arms that swing towards or away from the camera, like a fly seen from the front: a
    /// circle around the body looks like a line, and the arm shortens as it points at you.
    case flat(CGVector, CGVector)

    static func bones(_ upper: Double, _ lower: Double) -> Limb {
        .bones(Bone(upper), Bone(lower))
    }

    static func reach(_ x: Double, _ y: Double, bend: Double = 1) -> Limb {
        .reach(.point(CGPoint(x: x, y: y)), bend: bend)
    }
}

/// The whole figure at one moment. Scene units: a standing figure is about 1 tall, the floor
/// is y = 0 and y grows downwards, as on screen.
struct Pose: Sendable {
    var hip: CGPoint
    /// From the pelvis up to the middle of the back.
    var torso: Bone
    /// How far the upper back curls forward from the lower back, in degrees.
    var spine: Double = 0
    /// How far the head nods forward from the line of the upper back, in degrees.
    var nod: Double = 0
    /// Near and far from the side; screen right and left from the front or back.
    var arms: [Limb]
    var legs: [Limb]
    /// Absolute foot directions; nil keeps the ankle at a right angle to the shin.
    var feet: [Double?] = [nil, nil]
}

extension Pose {
    /// A pose seen from the side. The far limbs copy the near ones unless given.
    static func side(
        hip: (Double, Double), torso: Double, spine: Double = 0, nod: Double = 0,
        arm: Limb, farArm: Limb? = nil, leg: Limb, farLeg: Limb? = nil,
        foot: Double? = nil, farFoot: Double?? = nil
    ) -> Pose {
        Pose(
            hip: CGPoint(x: hip.0, y: hip.1), torso: Bone(torso), spine: spine, nod: nod,
            arms: [arm, farArm ?? arm], legs: [leg, farLeg ?? leg],
            feet: [foot, farFoot ?? foot]
        )
    }

    /// A pose seen from the front or behind, built from the screen-right limbs. The left
    /// side mirrors them unless given.
    static func front(
        hip: (Double, Double), torso: Double = 180,
        arm: Limb, leftArm: Limb? = nil, leg: Limb, leftLeg: Limb? = nil,
        foot: Double? = nil
    ) -> Pose {
        let center = hip.0
        return Pose(
            hip: CGPoint(x: hip.0, y: hip.1), torso: Bone(torso),
            arms: [arm, leftArm ?? arm.mirrored(around: center)],
            legs: [leg, leftLeg ?? leg.mirrored(around: center)],
            feet: [foot, foot.map { -$0 }]
        )
    }
}

extension Limb {
    func mirrored(around x: Double) -> Limb {
        switch self {
        case let .bones(upper, lower):
            .bones(Bone(-upper.angle, length: upper.length), Bone(-lower.angle, length: lower.length))
        case let .reach(.point(p), bend):
            .reach(.point(CGPoint(x: 2 * x - p.x, y: p.y)), bend: bend)
        case .reach(.body, _):
            self
        case let .flat(upper, lower):
            .flat(CGVector(dx: -upper.dx, dy: upper.dy), CGVector(dx: -lower.dx, dy: lower.dy))
        }
    }
}

// MARK: - Blending

extension Pose {
    /// The pose `t` of the way from `a` to `b`. Both must describe each limb the same way.
    static func mix(_ a: Pose, _ b: Pose, _ t: Double) -> Pose {
        Pose(
            hip: mix(a.hip, b.hip, t),
            torso: mix(a.torso, b.torso, t),
            spine: mix(a.spine, b.spine, t),
            nod: mix(a.nod, b.nod, t),
            arms: zip(a.arms, b.arms).map { Limb.mix($0, $1, t) },
            legs: zip(a.legs, b.legs).map { Limb.mix($0, $1, t) },
            feet: zip(a.feet, b.feet).map { x, y in
                guard let x, let y else { return x ?? y }
                return mix(x, y, t)
            }
        )
    }

    static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    static func mix(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: mix(a.x, b.x, t), y: mix(a.y, b.y, t))
    }

    static func mix(_ a: Bone, _ b: Bone, _ t: Double) -> Bone {
        Bone(mix(a.angle, b.angle, t), length: mix(a.length, b.length, t))
    }
}

private extension Limb {
    static func mix(_ a: Limb, _ b: Limb, _ t: Double) -> Limb {
        switch (a, b) {
        case let (.bones(a1, a2), .bones(b1, b2)):
            return .bones(Pose.mix(a1, b1, t), Pose.mix(a2, b2, t))
        case let (.reach(ta, bendA), .reach(tb, _)):
            return .reach(Target.mix(ta, tb, t), bend: bendA)
        case let (.flat(a1, a2), .flat(b1, b2)):
            return .flat(a1 * (1 - t) + b1 * t, a2 * (1 - t) + b2 * t)
        default:
            preconditionFailure("A limb must be described the same way in both poses")
        }
    }
}

private extension Target {
    static func mix(_ a: Target, _ b: Target, _ t: Double) -> Target {
        switch (a, b) {
        case let (.point(p), .point(q)):
            return .point(Pose.mix(p, q, t))
        case let (.body(t1, o1), .body(t2, o2)):
            return .body(t: Pose.mix(t1, t2, t), out: Pose.mix(o1, o2, t))
        default:
            preconditionFailure("A target must be described the same way in both poses")
        }
    }
}
