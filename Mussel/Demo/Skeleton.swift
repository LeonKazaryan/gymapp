import CoreGraphics
import Foundation

/// Body proportions in scene units, for a figure about 1 tall.
enum Body {
    static let lowerBack = 0.14
    static let upperBack = 0.16
    static let neck = 0.03
    static let headRadius = 0.062
    static let upperArm = 0.18
    /// Elbow to the middle of the grip.
    static let forearm = 0.19
    static let thigh = 0.245
    static let shin = 0.25
    static let toes = 0.1
    static let heel = 0.035
    /// Half the distance between the shoulders and between the hips, seen from the front.
    static let shoulderSpan = 0.105
    static let hipSpan = 0.06
    /// How far the far limbs sit from the near ones on screen, seen from the side.
    static let depth = CGVector(dx: -0.016, dy: -0.01)
}

/// A pose solved into points.
struct Skeleton: Sendable {
    struct Chain: Sendable {
        var root: CGPoint
        var joint: CGPoint
        var end: CGPoint
    }

    var camera: Camera
    var hip: CGPoint
    var waist: CGPoint
    var neck: CGPoint
    var head: CGPoint
    var arms: [Chain]
    var legs: [Chain]
    var toes: [CGPoint]
    var heels: [CGPoint]

    init(_ pose: Pose, camera: Camera) {
        self.camera = camera
        hip = pose.hip
        let lowerDir = direction(pose.torso.angle)
        let upperDir = direction(pose.torso.angle - pose.spine)
        waist = hip + lowerDir * (Body.lowerBack * pose.torso.length)
        neck = waist + upperDir * (Body.upperBack * pose.torso.length)
        head = neck + direction(pose.torso.angle - pose.spine - pose.nod) * (Body.neck + Body.headRadius)

        // From the front the shoulders and hips spread to the sides of the spine.
        let across = CGVector(dx: -upperDir.dy, dy: upperDir.dx)
        arms = []
        legs = []
        toes = []
        heels = []
        for index in 0..<2 {
            let side: Double = index == 0 ? 1 : -1
            let spread = camera == .side ? 0 : side
            let shoulder = neck + across * (Body.shoulderSpan * spread)
            let hipJoint = hip + across * (Body.hipSpan * spread)
            // Seen from the front, the left limbs mirror the right ones, so they bend the other way.
            let mirror = camera == .side ? 1.0 : side
            var arm = solve(pose.arms[index], from: shoulder, lengths: (Body.upperArm, Body.forearm), bend: -mirror)
            var leg = solve(pose.legs[index], from: hipJoint, lengths: (Body.thigh, Body.shin), bend: mirror)
            let shin = leg.end - leg.joint
            // From the front the feet point at the camera, so only a stub shows.
            let footAngle = pose.feet[index] ?? (angle(of: shin) + (camera == .side ? 90 : 60 * side))
            let footDir = direction(footAngle)
            let toeLength = camera == .side ? Body.toes : Body.toes * 0.45
            var toe = leg.end + footDir * toeLength
            var heel = leg.end - footDir * (camera == .side ? Body.heel : 0)
            if camera == .side && index == 1 {
                arm.offset(by: Body.depth)
                leg.offset(by: Body.depth)
                toe = toe + Body.depth
                heel = heel + Body.depth
            }
            arms.append(arm)
            legs.append(leg)
            toes.append(toe)
            heels.append(heel)
        }
    }

    /// A point `t` along the back from the hip (0) to the shoulders (1), and the direction
    /// the back runs there.
    func spinePoint(_ t: Double) -> (point: CGPoint, direction: CGVector) {
        let lowerShare = Body.lowerBack / (Body.lowerBack + Body.upperBack)
        if t <= lowerShare {
            let d = waist - hip
            return (hip + d * (t / lowerShare), d.normalized)
        }
        let d = neck - waist
        return (waist + d * ((t - lowerShare) / (1 - lowerShare)), d.normalized)
    }

    /// The torso's front at a point on the back: where the chest and belly face.
    static func front(ofSpine direction: CGVector) -> CGVector {
        CGVector(dx: -direction.dy, dy: direction.dx)
    }

    private func solve(_ limb: Limb, from root: CGPoint, lengths: (Double, Double), bend: Double) -> Chain {
        switch limb {
        case let .bones(upper, lower):
            let joint = root + direction(upper.angle) * (lengths.0 * upper.length)
            let end = joint + direction(lower.angle) * (lengths.1 * lower.length)
            return Chain(root: root, joint: joint, end: end)
        case let .flat(upper, lower):
            let joint = root + upper * lengths.0
            return Chain(root: root, joint: joint, end: joint + lower * lengths.1)
        case let .reach(target, flip):
            let goal: CGPoint
            switch target {
            case let .point(p):
                goal = p
            case let .body(t, out):
                let (point, dir) = spinePoint(t)
                goal = camera == .side ? point + Skeleton.front(ofSpine: dir) * out : point
            }
            return Skeleton.reach(from: root, to: goal, lengths: lengths, bend: bend * flip)
        }
    }

    /// Two-bone reach: the end goes as close to `goal` as the limb allows, the middle joint
    /// to the `bend` side of the line.
    static func reach(from root: CGPoint, to goal: CGPoint, lengths: (Double, Double), bend: Double) -> Chain {
        let (a, b) = lengths
        let line = goal - root
        let distance = max(line.length, 1e-6)
        let u = line / distance
        let r = min(max(distance, abs(a - b) + 1e-4), a + b - 1e-4)
        let cosA = (a * a + r * r - b * b) / (2 * a * r)
        let sinA = (1 - cosA * cosA).squareRoot()
        let side = CGVector(dx: u.dy, dy: -u.dx) * bend
        let joint = root + (u * cosA + side * sinA) * a
        return Chain(root: root, joint: joint, end: root + u * r)
    }
}

private extension Skeleton.Chain {
    mutating func offset(by v: CGVector) {
        root = root + v
        joint = joint + v
        end = end + v
    }
}

// MARK: - Geometry helpers

/// The unit vector of a bone direction (see `Bone`).
func direction(_ degrees: Double) -> CGVector {
    let r = degrees * .pi / 180
    return CGVector(dx: sin(r), dy: cos(r))
}

/// The bone direction of a vector.
func angle(of v: CGVector) -> Double {
    atan2(v.dx, v.dy) * 180 / .pi
}

extension CGVector {
    var length: Double { (dx * dx + dy * dy).squareRoot() }
    var normalized: CGVector { length > 0 ? self / length : self }
    /// The vector turned a quarter towards the bone's front: a limb hanging down faces right.
    var front: CGVector { CGVector(dx: dy, dy: -dx) }

    static func * (v: CGVector, k: Double) -> CGVector { CGVector(dx: v.dx * k, dy: v.dy * k) }
    static func / (v: CGVector, k: Double) -> CGVector { CGVector(dx: v.dx / k, dy: v.dy / k) }
    static func + (a: CGVector, b: CGVector) -> CGVector { CGVector(dx: a.dx + b.dx, dy: a.dy + b.dy) }
    static prefix func - (v: CGVector) -> CGVector { CGVector(dx: -v.dx, dy: -v.dy) }
}

extension CGPoint {
    static func + (p: CGPoint, v: CGVector) -> CGPoint { CGPoint(x: p.x + v.dx, y: p.y + v.dy) }
    static func - (p: CGPoint, v: CGVector) -> CGPoint { CGPoint(x: p.x - v.dx, y: p.y - v.dy) }
    static func - (a: CGPoint, b: CGPoint) -> CGVector { CGVector(dx: a.x - b.x, dy: a.y - b.y) }
}
