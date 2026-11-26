import CoreGraphics
import Foundation

/// One exercise acted out: the figure moves between a start pose and a turning pose, with the
/// machine around it and the working muscles lit.
struct Demo: Sendable {
    var camera: Camera = .side
    /// Where each rep starts.
    var start: Pose
    /// Where each rep turns around. Two of them alternate, e.g. left side, then right.
    var ends: [Pose]
    var tempo: Tempo
    var props: [Prop]
    var muscles: [Muscle]
    /// Off for scenes seen from above, where a floor line makes no sense.
    var showsFloor = true

    init(camera: Camera = .side, tempo: Tempo, muscles: [Muscle], start: Pose, end: Pose, alternate: Pose? = nil, props: [Prop]) {
        self.camera = camera
        self.start = start
        self.ends = [end] + (alternate.map { [$0] } ?? [])
        self.tempo = tempo
        self.props = props
        self.muscles = muscles
    }
}

/// How a rep is paced, so the slow half is the lowering, as a coach would ask.
enum Tempo: Sendable {
    /// The start is the easy position: lift first, then lower slowly (a curl).
    case liftFirst
    /// The start is the top: lower slowly first, then drive back (a squat).
    case lowerFirst
    /// A held position that only breathes (a plank).
    case hold

    /// Seconds for each part of a rep: rest at start, go, rest at the turn, come back.
    var beats: (rest: Double, go: Double, turn: Double, back: Double) {
        switch self {
        case .liftFirst: (0.45, 1.0, 0.35, 1.7)
        case .lowerFirst: (0.45, 1.7, 0.25, 1.0)
        case .hold: (0, 2.2, 0, 2.2)
        }
    }

    var repDuration: Double {
        let b = beats
        return b.rest + b.go + b.turn + b.back
    }
}

/// A moment of a demo: which turn pose the rep heads for and how far along it is.
struct DemoMoment: Sendable {
    var end: Int
    /// 0 at the start pose, 1 at the turn.
    var progress: Double
}

extension Demo {
    var cycleDuration: Double { tempo.repDuration * Double(ends.count) }

    func moment(at time: Double) -> DemoMoment {
        let rep = tempo.repDuration
        let cycle = time.truncatingRemainder(dividingBy: cycleDuration)
        let end = min(Int(cycle / rep), ends.count - 1)
        var t = cycle - Double(end) * rep
        let b = tempo.beats
        let progress: Double
        if t < b.rest {
            progress = 0
        } else if (t - b.rest) < b.go {
            progress = ease((t - b.rest) / b.go)
        } else if (t - b.rest - b.go) < b.turn {
            progress = 1
        } else {
            t -= b.rest + b.go + b.turn
            progress = 1 - ease(min(t / b.back, 1))
        }
        return DemoMoment(end: end, progress: progress)
    }

    func pose(at moment: DemoMoment) -> Pose {
        Pose.mix(start, ends[moment.end], moment.progress)
    }

    /// How far the weight is lifted, 0…1: the stack rides on it.
    func load(at moment: DemoMoment) -> Double {
        tempo == .lowerFirst ? 1 - moment.progress : moment.progress
    }

    private func ease(_ t: Double) -> Double { t * t * (3 - 2 * t) }
}

// MARK: - Props

/// A piece of the machine or the weight, drawn around the figure.
struct Prop: Sendable {
    enum Shape: Sendable {
        /// A flat rounded slab between two points: a seat, a backrest, a platform.
        case slab(Anchor, Anchor, thickness: Double)
        /// A rod with round ends: a frame, a lever, a bar, a rail.
        case rod(Anchor, Anchor, width: Double)
        /// A round thing: a plate, a roller pad, a pulley.
        case disc(Anchor, radius: Double)
        /// A thin cable through the given points.
        case cable([Anchor])
        /// A weight stack standing on `base`; its top plates ride on the load.
        case stack(base: CGPoint, height: Double)
        /// A dumbbell held at a point, seen end-on or along a direction.
        case dumbbell(Anchor, along: DumbbellAxis)
    }

    enum Material: Sendable {
        case frame, pad, metal, plate, cable
    }

    enum Layer: Sendable {
        /// Behind the whole figure.
        case back
        /// Behind the torso but in front of the far limbs, from the side.
        case far
        /// In front of the torso but behind the near limbs, from the side: a chest pad, an arm pad.
        case mid
        /// In front of everything.
        case front
    }

    var shape: Shape
    var material: Material
    var layer: Layer
}

enum DumbbellAxis: Sendable {
    /// The handle points at the camera: a round plate.
    case endOn
    /// The handle runs along a bone, e.g. held upright with both hands.
    case bone(BoneRef)
    case angle(Double)
}

/// A point a prop hangs on.
enum Anchor: Sendable {
    case at(CGPoint)
    /// Rides on the load: at `point` at rest and `travel` further when fully lifted.
    case load(CGPoint, travel: CGVector)
    /// On a bone, `t` along it from its root and `out` to its front (the shin's front, the
    /// chest), in scene units.
    case on(BoneRef, t: Double = 1, out: Double = 0)

    static func at(_ x: Double, _ y: Double) -> Anchor { .at(CGPoint(x: x, y: y)) }

    /// The middle of the grip.
    static func hand(_ index: Int) -> Anchor { .on(.forearm(index)) }
    static func ankle(_ index: Int) -> Anchor { .on(.shin(index)) }
}

enum BoneRef: Sendable {
    case torso
    case upperArm(Int), forearm(Int)
    case thigh(Int), shin(Int)
    /// From the ankle to the toes.
    case foot(Int)

    /// Whether the bone belongs to the far side from the side camera.
    var isFar: Bool {
        switch self {
        case .torso: false
        case let .upperArm(i), let .forearm(i), let .thigh(i), let .shin(i), let .foot(i): i == 1
        }
    }
}

extension Prop {
    static func slab(_ a: Anchor, _ b: Anchor, _ thickness: Double = 0.05, _ material: Material = .pad, layer: Layer = .back) -> Prop {
        Prop(shape: .slab(a, b, thickness: thickness), material: material, layer: layer)
    }

    static func rod(_ a: Anchor, _ b: Anchor, _ width: Double = 0.03, _ material: Material = .frame, layer: Layer = .back) -> Prop {
        Prop(shape: .rod(a, b, width: width), material: material, layer: layer)
    }

    static func disc(_ a: Anchor, _ radius: Double, _ material: Material = .pad, layer: Layer = .back) -> Prop {
        Prop(shape: .disc(a, radius: radius), material: material, layer: layer)
    }

    static func cable(_ points: Anchor...) -> Prop {
        Prop(shape: .cable(points), material: .cable, layer: .back)
    }

    static func stack(_ x: Double, height: Double = 0.62, base: Double = 0) -> Prop {
        Prop(shape: .stack(base: CGPoint(x: x, y: base), height: height), material: .plate, layer: .back)
    }

    static func dumbbell(_ a: Anchor, along axis: DumbbellAxis = .endOn, layer: Layer = .front) -> Prop {
        Prop(shape: .dumbbell(a, along: axis), material: .plate, layer: layer)
    }

    /// A barbell end with a light plate, seen from the side.
    static func barbell(_ a: Anchor, radius: Double = 0.085, layer: Layer = .front) -> Prop {
        .disc(a, radius, .plate, layer: layer)
    }

    /// How far the top of a stack rises when the weight is fully lifted.
    static let stackTravel = 0.16
}
