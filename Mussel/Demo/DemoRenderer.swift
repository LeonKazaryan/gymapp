import SwiftUI

/// Colors of a demo. The figure is light, the machine stays dark and quiet, and the working
/// muscles are the one warm color.
struct DemoStyle: Sendable {
    var body = Color(rgb: 0xE6E9F0)
    var farBody = Color(rgb: 0x7F889B)
    var muscle = Palette.muscle
    var farMuscle = Color(rgb: 0x9C4236)
    var frame = Color(rgb: 0x353C4C)
    var pad = Color(rgb: 0x272D3A)
    var padRim = Color(rgb: 0x414A5E)
    var metal = Color(rgb: 0x9AA3B5)
    var plate = Color(rgb: 0x485166)
    var plateRim = Color(rgb: 0x6A7489)
    var cable = Color(rgb: 0xAEB6C6)
    var floor = Color(rgb: 0x3A4150)

    static let standard = DemoStyle()
}

/// Line widths of the figure, in scene units.
private enum Thickness {
    static let torso = 0.118
    static let neck = 0.046
    static let upperArm = 0.058
    static let forearm = 0.05
    static let hand = 0.031
    static let thigh = 0.088
    static let shin = 0.066
    static let foot = 0.042
}

/// Draws one moment of a demo into a canvas.
struct DemoRenderer {
    let demo: Demo
    /// The part of the scene to show.
    let frame: CGRect
    var style: DemoStyle = .standard

    func draw(_ moment: DemoMoment, in context: inout GraphicsContext, size: CGSize) {
        var context = context
        fit(&context, size: size)
        let skeleton = Skeleton(demo.pose(at: moment), camera: demo.camera)
        let load = demo.load(at: moment)
        if demo.showsFloor { drawFloor(&context) }
        drawProps(.back, skeleton: skeleton, load: load, in: &context)
        drawFigure(skeleton, load: load, in: &context)
        drawProps(.front, skeleton: skeleton, load: load, in: &context)
    }

    /// The turn pose over a faint start pose, for when nothing should move.
    func drawStill(in context: inout GraphicsContext, size: CGSize) {
        var context = context
        fit(&context, size: size)
        let turn = DemoMoment(end: 0, progress: 1)
        let skeleton = Skeleton(demo.pose(at: turn), camera: demo.camera)
        let load = demo.load(at: turn)
        if demo.showsFloor { drawFloor(&context) }
        drawProps(.back, skeleton: skeleton, load: load, in: &context)
        var ghost = context
        ghost.opacity = 0.22
        drawFigure(Skeleton(demo.start, camera: demo.camera), load: load, in: &ghost, muscles: false)
        drawFigure(skeleton, load: load, in: &context)
        drawProps(.front, skeleton: skeleton, load: load, in: &context)
    }

    private func fit(_ context: inout GraphicsContext, size: CGSize) {
        let scale = min(size.width / frame.width, size.height / frame.height)
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -frame.midX, y: -frame.midY)
    }

    private func drawFloor(_ context: inout GraphicsContext) {
        let left = frame.minX, right = frame.maxX
        var path = Path()
        path.move(to: CGPoint(x: left, y: 0.006))
        path.addLine(to: CGPoint(x: right, y: 0.006))
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: style.floor.opacity(0), location: 0),
                    .init(color: style.floor, location: 0.25),
                    .init(color: style.floor, location: 0.75),
                    .init(color: style.floor.opacity(0), location: 1),
                ]),
                startPoint: CGPoint(x: left, y: 0), endPoint: CGPoint(x: right, y: 0)
            ),
            style: StrokeStyle(lineWidth: 0.012, lineCap: .round)
        )
    }

    // MARK: Figure

    private func drawFigure(_ s: Skeleton, load: Double, in context: inout GraphicsContext, muscles: Bool = true) {
        let lit = muscles ? demo.muscles : []
        switch s.camera {
        case .side:
            drawLeg(1, s, lit, &context)
            drawArm(1, s, lit, &context)
            drawProps(.far, skeleton: s, load: load, in: &context)
            drawTorso(s, lit, &context)
            drawProps(.mid, skeleton: s, load: load, in: &context)
            drawLeg(0, s, lit, &context)
            drawArm(0, s, lit, &context)
        case .front:
            drawTorso(s, lit, &context)
            drawProps(.far, skeleton: s, load: load, in: &context)
            drawProps(.mid, skeleton: s, load: load, in: &context)
            for i in 0..<2 { drawLeg(i, s, lit, &context) }
            for i in 0..<2 { drawArm(i, s, lit, &context) }
        case .back:
            for i in 0..<2 { drawLeg(i, s, lit, &context) }
            for i in 0..<2 { drawArm(i, s, lit, &context) }
            drawProps(.far, skeleton: s, load: load, in: &context)
            drawTorso(s, lit, &context)
            drawProps(.mid, skeleton: s, load: load, in: &context)
        }
    }

    private func isFar(_ index: Int, _ s: Skeleton) -> Bool { s.camera == .side && index == 1 }

    private func drawArm(_ i: Int, _ s: Skeleton, _ lit: [Muscle], _ context: inout GraphicsContext) {
        let arm = s.arms[i]
        let color = isFar(i, s) ? style.farBody : style.body
        stroke([arm.root, arm.joint], Thickness.upperArm, color, &context)
        stroke([arm.joint, arm.end], Thickness.forearm, color, &context)
        let hand = arm.end
        context.fill(Path(ellipseIn: CGRect(x: hand.x - Thickness.hand, y: hand.y - Thickness.hand, width: Thickness.hand * 2, height: Thickness.hand * 2)), with: .color(color))
        for muscle in lit { highlight(muscle, arm: i, s, &context) }
    }

    private func drawLeg(_ i: Int, _ s: Skeleton, _ lit: [Muscle], _ context: inout GraphicsContext) {
        let leg = s.legs[i]
        let color = isFar(i, s) ? style.farBody : style.body
        stroke([leg.root, leg.joint], Thickness.thigh, color, &context)
        stroke([leg.joint, leg.end], Thickness.shin, color, &context)
        stroke([s.heels[i], s.toes[i]], Thickness.foot, color, &context)
        for muscle in lit { highlight(muscle, leg: i, s, &context) }
    }

    private func drawTorso(_ s: Skeleton, _ lit: [Muscle], _ context: inout GraphicsContext) {
        let color = style.body
        if s.camera == .side {
            stroke([s.hip, s.waist, s.neck], Thickness.torso, color, &context)
        } else {
            // A rounded trapezoid: shoulders wider than the hips.
            let up = (s.neck - s.waist).normalized
            let across = CGVector(dx: -up.dy, dy: up.dx)
            let shoulders = Body.shoulderSpan + 0.012
            let hips = Body.hipSpan + 0.03
            var shape = Path()
            shape.move(to: s.neck + across * shoulders)
            shape.addLine(to: s.waist + across * (hips + 0.008))
            shape.addLine(to: s.hip + across * hips)
            shape.addLine(to: s.hip - across * hips)
            shape.addLine(to: s.waist - across * (hips + 0.008))
            shape.addLine(to: s.neck - across * shoulders)
            shape.closeSubpath()
            context.fill(shape, with: .color(color))
            context.stroke(shape, with: .color(color), style: StrokeStyle(lineWidth: 0.06, lineJoin: .round))
        }
        stroke([s.neck, s.head], Thickness.neck, color, &context)
        let r = Body.headRadius
        context.fill(Path(ellipseIn: CGRect(x: s.head.x - r, y: s.head.y - r, width: r * 2, height: r * 2)), with: .color(color))
        for muscle in lit { highlightTorso(muscle, s, &context) }
    }

    private func stroke(_ points: [CGPoint], _ width: Double, _ color: Color, _ context: inout GraphicsContext) {
        var path = Path()
        path.addLines(points)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    // MARK: Muscles

    /// A lit strip along part of a bone, pushed to its front (positive) or back.
    private func strip(_ from: CGPoint, _ to: CGPoint, t: ClosedRange<Double>, out: Double, width: Double, far: Bool, _ context: inout GraphicsContext) {
        let d = to - from
        let side = d.normalized.front * out
        let a = from + d * t.lowerBound + side
        let b = from + d * t.upperBound + side
        glow([a, b], width: width, far: far, &context)
    }

    private func glow(_ points: [CGPoint], width: Double, far: Bool, _ context: inout GraphicsContext) {
        var path = Path()
        path.addLines(points)
        let color = far ? style.farMuscle : style.muscle
        context.stroke(path, with: .color(color.opacity(0.28)), style: StrokeStyle(lineWidth: width * 1.9, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func dot(_ center: CGPoint, _ radius: Double, far: Bool, _ context: inout GraphicsContext) {
        glow([center, center], width: radius * 2, far: far, &context)
    }

    private func highlight(_ muscle: Muscle, arm i: Int, _ s: Skeleton, _ context: inout GraphicsContext) {
        let arm = s.arms[i]
        let far = isFar(i, s)
        let w = Thickness.upperArm
        let sign = outward(i, s)
        switch (s.camera, muscle) {
        case (.side, .biceps): strip(arm.root, arm.joint, t: 0.3...0.8, out: w * 0.2, width: w * 0.5, far: far, &context)
        case (.side, .triceps): strip(arm.root, arm.joint, t: 0.25...0.8, out: -w * 0.2, width: w * 0.5, far: far, &context)
        case (.side, .shoulders): strip(arm.root, arm.joint, t: 0.04...0.2, out: w * 0.05, width: w * 0.8, far: far, &context)
        case (.side, .rearDelts): strip(arm.root, arm.joint, t: 0.04...0.2, out: -w * 0.18, width: w * 0.6, far: far, &context)
        case (.front, .biceps), (.back, .triceps):
            strip(arm.root, arm.joint, t: 0.3...0.8, out: 0, width: w * 0.5, far: far, &context)
        case (.front, .shoulders), (.back, .shoulders), (.back, .rearDelts):
            dot(arm.root + (arm.root - s.neck).normalized * 0.01, 0.034, far: far, &context)
        case (.front, .triceps):
            strip(arm.root, arm.joint, t: 0.3...0.8, out: w * 0.25 * sign, width: w * 0.35, far: far, &context)
        default: break
        }
    }

    private func highlight(_ muscle: Muscle, leg i: Int, _ s: Skeleton, _ context: inout GraphicsContext) {
        let leg = s.legs[i]
        let far = isFar(i, s)
        let w = Thickness.thigh
        let sign = outward(i, s)
        switch (s.camera, muscle) {
        case (.side, .quads): strip(leg.root, leg.joint, t: 0.18...0.8, out: w * 0.2, width: w * 0.48, far: far, &context)
        case (.side, .hamstrings): strip(leg.root, leg.joint, t: 0.22...0.8, out: -w * 0.2, width: w * 0.45, far: far, &context)
        case (.side, .adductors): strip(leg.root, leg.joint, t: 0.15...0.6, out: 0, width: w * 0.35, far: far, &context)
        case (.side, .calves), (.back, .calves), (.front, .calves):
            strip(leg.joint, leg.end, t: 0.12...0.48, out: s.camera == .side ? -Thickness.shin * 0.18 : 0, width: Thickness.shin * 0.55, far: far, &context)
        case (.side, .glutes):
            let (_, dir) = s.spinePoint(0)
            let back = -Skeleton.front(ofSpine: dir)
            let thighDir = (leg.joint - leg.root).normalized
            dot(leg.root + back * 0.04 + thighDir * 0.025, 0.04, far: far, &context)
        case (.front, .quads), (.back, .hamstrings):
            strip(leg.root, leg.joint, t: 0.18...0.82, out: 0, width: w * 0.5, far: far, &context)
        case (.front, .adductors):
            strip(leg.root, leg.joint, t: 0.08...0.6, out: -w * 0.24 * sign, width: w * 0.4, far: far, &context)
        case (.front, .glutes):
            dot(leg.root + CGVector(dx: 0.035 * sign, dy: -0.005), 0.032, far: far, &context)
        case (.back, .glutes):
            dot(leg.root + CGVector(dx: -0.012 * sign, dy: 0.035), 0.05, far: far, &context)
        default: break
        }
    }

    private func highlightTorso(_ muscle: Muscle, _ s: Skeleton, _ context: inout GraphicsContext) {
        let w = Thickness.torso
        if s.camera == .side {
            func band(_ t: ClosedRange<Double>, _ out: Double, _ width: Double) {
                let points = (0...6).map { k in
                    let (p, dir) = s.spinePoint(t.lowerBound + (t.upperBound - t.lowerBound) * Double(k) / 6)
                    return p + Skeleton.front(ofSpine: dir) * out
                }
                glow(points, width: width, far: false, &context)
            }
            switch muscle {
            case .abs: band(0.12...0.55, w * 0.24, w * 0.4)
            case .chest: band(0.68...0.88, w * 0.24, w * 0.42)
            case .lats: band(0.42...0.82, -w * 0.22, w * 0.42)
            case .upperBack: band(0.76...0.94, -w * 0.24, w * 0.42)
            case .lowerBack: band(0.08...0.4, -w * 0.24, w * 0.38)
            default: break
            }
            return
        }
        let up = (s.neck - s.waist).normalized
        let across = CGVector(dx: -up.dy, dy: up.dx)
        func at(_ t: Double, _ x: Double) -> CGPoint { s.spinePoint(t).point + across * x }
        switch (s.camera, muscle) {
        case (.front, .chest):
            for x in [0.048, -0.048] { glow([at(0.8, x * 0.7), at(0.8, x * 1.25)], width: 0.06, far: false, &context) }
        case (.front, .abs):
            glow([at(0.16, 0), at(0.58, 0)], width: 0.055, far: false, &context)
        case (.front, .lats), (.back, .lats):
            for x in [0.088, -0.088] { glow([at(0.46, x * 0.95), at(0.82, x * 1.1)], width: 0.03, far: false, &context) }
        case (.back, .upperBack):
            for x in [0.042, -0.042] { glow([at(0.76, x), at(0.92, x * 1.2)], width: 0.05, far: false, &context) }
        case (.back, .lowerBack):
            for x in [0.026, -0.026] { glow([at(0.08, x), at(0.4, x)], width: 0.026, far: false, &context) }
        default: break
        }
    }

    /// From the front or back: +1 for the limb on the screen's right, −1 on the left.
    private func outward(_ index: Int, _ s: Skeleton) -> Double {
        s.camera == .side ? 1 : (index == 0 ? 1 : -1)
    }

    // MARK: Props

    private func drawProps(_ layer: Prop.Layer, skeleton s: Skeleton, load: Double, in context: inout GraphicsContext) {
        for prop in demo.props where prop.layer == layer {
            draw(prop, s, load: load, &context)
        }
    }

    private func draw(_ prop: Prop, _ s: Skeleton, load: Double, _ context: inout GraphicsContext) {
        switch prop.shape {
        case let .slab(a, b, thickness):
            let p = s.point(a, load: load), q = s.point(b, load: load)
            let path = slabPath(p, q, thickness)
            context.fill(path, with: .color(fill(prop.material)))
            if prop.material == .pad {
                context.stroke(path, with: .color(style.padRim), lineWidth: 0.007)
            }
        case let .rod(a, b, width):
            stroke([s.point(a, load: load), s.point(b, load: load)], width, fill(prop.material), &context)
        case let .disc(a, radius):
            let c = s.point(a, load: load)
            let circle = Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
            context.fill(circle, with: .color(fill(prop.material)))
            switch prop.material {
            case .plate:
                context.stroke(circle, with: .color(style.plateRim), lineWidth: radius * 0.16)
                let hub = radius * 0.24
                context.fill(Path(ellipseIn: CGRect(x: c.x - hub, y: c.y - hub, width: hub * 2, height: hub * 2)), with: .color(style.metal))
            case .pad:
                context.stroke(circle, with: .color(style.padRim), lineWidth: 0.007)
            default:
                break
            }
        case let .cable(anchors):
            let points = anchors.map { s.point($0, load: load) }
            var path = Path()
            path.addLines(points)
            context.stroke(path, with: .color(style.cable.opacity(0.85)), style: StrokeStyle(lineWidth: 0.0065, lineCap: .round, lineJoin: .round))
            for (anchor, point) in zip(anchors, points).dropFirst().dropLast() {
                if case .at = anchor { pulley(point, &context) }
            }
        case let .stack(base, height):
            drawStack(base: base, height: height, load: load, &context)
        case let .dumbbell(a, axis):
            let c = s.point(a, load: load)
            switch axis {
            case .endOn:
                draw(Prop.disc(.at(c), 0.05, .plate), s, load: load, &context)
            case let .bone(ref):
                let (p, q) = s.ends(of: ref)
                dumbbellProfile(c, direction: (q - p).normalized, &context)
            case let .angle(degrees):
                dumbbellProfile(c, direction: direction(degrees), &context)
            }
        }
    }

    private func fill(_ material: Prop.Material) -> Color {
        switch material {
        case .frame: style.frame
        case .pad: style.pad
        case .metal: style.metal
        case .plate: style.plate
        case .cable: style.cable
        }
    }

    private func slabPath(_ p: CGPoint, _ q: CGPoint, _ thickness: Double) -> Path {
        let d = q - p
        let length = d.length
        let rect = CGRect(x: 0, y: -thickness / 2, width: length, height: thickness)
        let transform = CGAffineTransform(translationX: p.x, y: p.y).rotated(by: atan2(d.dy, d.dx))
        return Path(roundedRect: rect, cornerRadius: min(thickness * 0.45, 0.022), style: .continuous).applying(transform)
    }

    private func pulley(_ c: CGPoint, _ context: inout GraphicsContext) {
        let r = 0.024
        let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        context.fill(circle, with: .color(style.frame))
        context.stroke(circle, with: .color(style.metal.opacity(0.7)), lineWidth: 0.006)
    }

    private func dumbbellProfile(_ c: CGPoint, direction d: CGVector, _ context: inout GraphicsContext) {
        let half = 0.075
        stroke([c - d * half, c + d * half], 0.02, style.metal, &context)
        for end in [-1.0, 1.0] {
            let center = c + d * (half * end)
            let path = slabPath(center - d.front * 0.05, center + d.front * 0.05, 0.035)
            context.fill(path, with: .color(style.plate))
            context.stroke(path, with: .color(style.plateRim), lineWidth: 0.006)
        }
    }

    private func drawStack(base: CGPoint, height: Double, load: Double, _ context: inout GraphicsContext) {
        let width = 0.15
        let count = 12
        let moving = 4
        let pitch = height / Double(count)
        let lift = load * Prop.stackTravel
        // Guide rods run past the top so the lifted plates still sit on them.
        for x in [-width * 0.3, width * 0.3] {
            stroke([CGPoint(x: base.x + x, y: base.y), CGPoint(x: base.x + x, y: base.y - height - Prop.stackTravel - 0.05)], 0.008, style.metal.opacity(0.55), &context)
        }
        for k in 0..<count {
            let isMoving = k >= count - moving
            let top = base.y - pitch * Double(k + 1) - (isMoving ? lift : 0)
            let rect = CGRect(x: base.x - width / 2, y: top + pitch * 0.12, width: width, height: pitch * 0.82)
            let plate = Path(roundedRect: rect, cornerRadius: 0.008)
            context.fill(plate, with: .color(isMoving ? style.plateRim : style.plate))
        }
        // The selector pin under the moving plates.
        let pinY = base.y - pitch * Double(count - moving) - lift + pitch * 0.5
        let pin = Path(ellipseIn: CGRect(x: base.x + width / 2 - 0.004, y: pinY - 0.012, width: 0.024, height: 0.024))
        context.fill(pin, with: .color(style.muscle))
    }
}

// MARK: - Anchors

extension Skeleton {
    func point(_ anchor: Anchor, load: Double) -> CGPoint {
        switch anchor {
        case let .at(p):
            return p
        case let .load(p, travel):
            return p + travel * load
        case let .on(ref, t, out):
            if case .torso = ref {
                let (p, dir) = spinePoint(t)
                return camera == .side ? p + Skeleton.front(ofSpine: dir) * out : p
            }
            let (a, b) = ends(of: ref)
            let d = b - a
            var side = d.normalized.front
            if camera != .side {
                // From the front, "out" means away from the middle of the body.
                let mid = a + d * t
                if (mid.x - hip.x) * side.dx < 0 { side = -side }
            }
            return a + d * t + side * out
        }
    }

    func ends(of ref: BoneRef) -> (CGPoint, CGPoint) {
        switch ref {
        case .torso: (hip, neck)
        case let .upperArm(i): (arms[i].root, arms[i].joint)
        case let .forearm(i): (arms[i].joint, arms[i].end)
        case let .thigh(i): (legs[i].root, legs[i].joint)
        case let .shin(i): (legs[i].joint, legs[i].end)
        case let .foot(i): (legs[i].end, toes[i])
        }
    }
}

// MARK: - Framing

extension Demo {
    /// The scene rectangle that holds the whole rep and the machine, with a little air.
    var bounds: CGRect {
        var xs: [Double] = [], ys: [Double] = showsFloor ? [0] : []
        func add(_ p: CGPoint, _ r: Double) {
            xs += [p.x - r, p.x + r]
            ys += [p.y - r, p.y + r]
        }
        for end in ends.indices {
            for progress in [0, 0.5, 1.0] {
                let moment = DemoMoment(end: end, progress: progress)
                let s = Skeleton(pose(at: moment), camera: camera)
                let load = self.load(at: moment)
                add(s.head, Body.headRadius + 0.01)
                for chain in s.arms + s.legs {
                    for p in [chain.root, chain.joint, chain.end] { add(p, 0.05) }
                }
                for p in s.toes + s.heels + [s.hip, s.neck] { add(p, 0.06) }
                for prop in props {
                    switch prop.shape {
                    case let .slab(a, b, t): for x in [a, b] { add(s.point(x, load: load), t) }
                    case let .rod(a, b, w): for x in [a, b] { add(s.point(x, load: load), w) }
                    case let .disc(a, r): add(s.point(a, load: load), r)
                    case let .cable(list): for x in list { add(s.point(x, load: load), 0.02) }
                    case let .stack(base, height):
                        add(base, 0.08)
                        add(CGPoint(x: base.x, y: base.y - height - Prop.stackTravel - 0.05), 0.08)
                    case let .dumbbell(a, _): add(s.point(a, load: load), 0.09)
                    }
                }
            }
        }
        let minX = xs.min() ?? -0.5, maxX = xs.max() ?? 0.5
        let minY = ys.min() ?? -1, maxY = ys.max() ?? 0
        let pad = 0.06
        return CGRect(x: minX - pad, y: minY - pad, width: maxX - minX + pad * 2, height: maxY - minY + pad * 2)
    }
}
