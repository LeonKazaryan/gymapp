import SwiftUI

/// The bottom of the workout screen: whatever the person does next.
struct WorkoutControls: View {
    @Binding var run: WorkoutRun
    let onPain: () -> Void

    var body: some View {
        Group {
            switch run.stage {
            case .lifting:
                SetPanel(run: $run, onPain: onPain)
            case .repsLeft:
                ChoicePanel(
                    title: String(localized: "How many more reps could you have done?"),
                    choices: [
                        (String(localized: "0–1"), String(localized: "Heavy"), { run.answer(.few, at: .now) }),
                        (String(localized: "2–3"), String(localized: "Just right"), { run.answer(.some, at: .now) }),
                        (String(localized: "4+"), String(localized: "Light"), { run.answer(.plenty, at: .now) }),
                    ]
                )
            case .feeling:
                ChoicePanel(
                    title: String(localized: "How did the exercise feel?"),
                    choices: [
                        (String(localized: "Easy"), nil, { run.answer(.easy, at: .now) }),
                        (String(localized: "Normal"), nil, { run.answer(.normal, at: .now) }),
                        (String(localized: "Hard"), nil, { run.answer(.hard, at: .now) }),
                    ]
                )
            case let .resting(until):
                RestPanel(until: until, total: TimeInterval(run.plan.restSeconds), next: nextLine, onAdd: { run.addRest(15) }, onSkip: { run.endRest() })
            case .finished:
                EmptyView()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .padding(.bottom, 8)
    }

    private var nextLine: String {
        let current = run.current
        guard !run.sets.isEmpty else { return current.exercise.name }
        let reps = Format.reps(current.targetReps, current.prescription.unit)
        let set = String(localized: "Set \(run.sets.count + 1)")
        return current.exercise.hasWeight ? "\(set) · \(Format.kg(run.weight)) × \(reps)" : "\(set) · \(reps)"
    }
}

/// Weight and reps for the set about to be done, and the button that logs it.
private struct SetPanel: View {
    @Binding var run: WorkoutRun
    let onPain: () -> Void

    @State private var weight = 0.0
    @State private var reps = 0

    private struct Sync: Hashable {
        let index: Int
        let exercise: ExerciseID
        let sets: Int
        let weight: Double
    }

    var body: some View {
        let exercise = run.current.exercise
        let unit = run.current.prescription.unit
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                if exercise.hasWeight {
                    Adjuster(value: Format.kg(weight), caption: weightCaption(exercise)) {
                        weight = exercise.easier(weight)
                    } increment: {
                        weight = exercise.harder(weight)
                    }
                }
                Adjuster(value: "\(reps)", caption: unit == .seconds ? String(localized: "seconds") : String(localized: "reps")) {
                    reps = max(1, reps - (unit == .seconds ? 5 : 1))
                } increment: {
                    reps += unit == .seconds ? 5 : 1
                }
            }
            Button("Set done") {
                run.completeSet(weight: exercise.hasWeight ? weight : 0, reps: reps, at: .now)
            }
            .buttonStyle(.capsule())
            .sensoryFeedback(Haptics.setDone, trigger: run.sets.count)
            HStack {
                if !run.current.swaps.isEmpty {
                    small("Machine taken", icon: "arrow.triangle.swap") { run.swap() }
                }
                small("It hurts", icon: "bandage") { onPain() }
                small("Skip", icon: "forward") { run.skip(at: .now) }
            }
        }
        .onChange(of: Sync(index: run.index, exercise: run.current.prescription.exercise, sets: run.sets.count, weight: run.weight), initial: true) {
            weight = run.weight
            reps = run.current.targetReps
        }
    }

    /// What the number means on this kind of machine.
    private func weightCaption(_ exercise: Exercise) -> String {
        if exercise.weightIsPerHand { return String(localized: "each hand") }
        switch exercise.equipment {
        case .assisted: return String(localized: "counterweight")
        case .plateLoaded, .smith: return String(localized: "plates only")
        case .barbell: return String(localized: "with the bar")
        default: return String(localized: "weight")
        }
    }

    private func small(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondary)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.pressable)
    }
}

/// A number with − and + on either side. Holding a button repeats it.
private struct Adjuster: View {
    let value: String
    let caption: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                button("minus", decrement)
                    .accessibilityLabel(Text("Less"))
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
                button("plus", increment)
                    .accessibilityLabel(Text("More"))
            }
            Text(caption)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondary)
        }
        .padding(10)
        .card(cornerRadius: 20)
        .animation(Motion.snappy, value: value)
        .sensoryFeedback(Haptics.select, trigger: value)
    }

    private func button(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .foregroundStyle(Palette.text)
                .frame(width: 40, height: 40)
                .background(Palette.raised, in: Circle())
        }
        .buttonRepeatBehavior(.enabled)
    }
}

/// A question with three big answers.
private struct ChoicePanel: View {
    let title: String
    let choices: [(label: String, detail: String?, action: () -> Void)]

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ForEach(choices.indices, id: \.self) { i in
                    Button(action: choices[i].action) {
                        VStack(spacing: 4) {
                            Text(choices[i].label)
                                .font(.system(.title3, design: .rounded, weight: .heavy))
                                .foregroundStyle(Palette.text)
                            if let detail = choices[i].detail {
                                Text(detail)
                                    .font(Typography.caption)
                                    .foregroundStyle(Palette.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .card(cornerRadius: 20, fill: i == 1 ? Palette.accent.opacity(0.16) : Palette.surface)
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }
}

/// The rest between sets: a ring running down, then back to work on its own.
private struct RestPanel: View {
    let until: Date
    let total: TimeInterval
    let next: String
    let onAdd: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                TimelineView(.animation(minimumInterval: 1 / 20)) { context in
                    let left = max(0, until.timeIntervalSince(context.date))
                    ZStack {
                        Circle()
                            .stroke(Palette.raised, lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: min(1, left / max(total, left)))
                            .stroke(Palette.accentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(Duration.seconds(left.rounded(.up)).formatted(.time(pattern: .minuteSecond)))
                            .font(.system(.title2, design: .rounded, weight: .heavy).monospacedDigit())
                            .foregroundStyle(Palette.text)
                    }
                    .frame(width: 96, height: 96)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(String(localized: "Rest"))
                    Text(next)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button("+15 s", action: onAdd)
                    .buttonStyle(.capsule(.subtle))
                Button("Go", action: onSkip)
                    .buttonStyle(.capsule())
            }
        }
        .task(id: until) {
            let left = until.timeIntervalSinceNow
            if left > 0 { try? await Task.sleep(for: .seconds(left)) }
            guard !Task.isCancelled else { return }
            onSkip()
        }
    }
}
