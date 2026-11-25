import SwiftUI

/// An exercise acted out by the figure, looping.
///
/// With Reduce Motion it shows one still frame instead: the turn of the rep over a faint
/// start, so the movement still reads.
struct DemoView: View {
    let demo: Demo
    var isPlaying = true
    /// 1 is the real tempo; 0.5 is slow motion.
    var speed = 1.0
    /// Thumbnails in a grid can draw less often.
    var framesPerSecond = 60.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = Clock()

    var body: some View {
        let renderer = DemoRenderer(demo: demo, frame: demo.bounds)
        Group {
            if reduceMotion {
                Canvas { context, size in renderer.drawStill(in: &context, size: size) }
            } else {
                TimelineView(.animation(minimumInterval: 1 / framesPerSecond, paused: !isPlaying)) { timeline in
                    let moment = demo.moment(at: clock.time(at: timeline.date))
                    Canvas { context, size in renderer.draw(moment, in: &context, size: size) }
                }
            }
        }
        .onChange(of: isPlaying ? speed : 0, initial: true) { _, rate in
            clock.setRate(rate, at: .now)
        }
        .accessibilityHidden(true)
    }

    /// Demo time that can change speed or stop without jumping.
    private struct Clock {
        var origin = Date()
        var offset = 0.0
        var rate = 1.0

        func time(at date: Date) -> Double {
            offset + date.timeIntervalSince(origin) * rate
        }

        mutating func setRate(_ newRate: Double, at date: Date) {
            offset = time(at: date)
            origin = date
            rate = newRate
        }
    }
}

extension Exercise {
    var demo: Demo { Demos.of(id) }
}
