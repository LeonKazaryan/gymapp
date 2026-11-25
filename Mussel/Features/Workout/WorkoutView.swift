import SwiftUI

/// A workout, one exercise at a time: the demo on top, the sets in the middle, and at the
/// bottom whatever comes next: the set, a question, or the rest timer.
struct WorkoutView: View {
    @Environment(TrainingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var run: WorkoutRun
    @State private var saved: SavedWorkout?
    @State private var showTechnique = false
    @State private var confirmExit = false
    @State private var confirmPain = false
    @State private var showDoctor = false

    init(plan: PlannedWorkout) {
        _run = State(initialValue: WorkoutRun(plan: plan, started: .now))
    }

    var body: some View {
        Group {
            if let saved {
                WorkoutSummaryView(saved: saved) { dismiss() }
                    .transition(.opacity)
            } else {
                exerciseScreen
                    .transition(.opacity)
            }
        }
        .animation(Motion.smooth, value: saved == nil)
        .screenBackground()
        .onChange(of: run.stage) { _, stage in
            if stage == .finished { saved = store.save(run) }
        }
        .sensoryFeedback(Haptics.workoutDone, trigger: saved != nil) { _, done in done }
        #if DEBUG
        .task { playForDebugging() }
        #endif
        .sensoryFeedback(Haptics.restOver, trigger: run.stage) { old, new in
            if case .resting = old { return new == .lifting }
            return false
        }
    }

    #if DEBUG
    /// Plays the workout up to `-MusselDebugWorkoutStage`, for screenshots.
    private func playForDebugging() {
        guard let target = Debug.workoutStage else { return }
        for _ in 0..<200 {
            switch (target, run.stage) {
            case ("repsLeft", .repsLeft), ("rest", .resting), ("feeling", .feeling), (_, .finished):
                return
            case (_, .lifting):
                run.completeSet(weight: run.weight, reps: run.current.targetReps + 1, at: .now)
            case (_, .repsLeft):
                run.answer(.plenty, at: .now)
            case (_, .feeling):
                run.answer(.normal, at: .now)
            case (_, .resting):
                run.endRest()
            }
        }
    }
    #endif

    private var exerciseScreen: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DemoView(demo: run.current.exercise.demo)
                        .aspectRatio(1.45, contentMode: .fit)
                        .demoStage(cornerRadius: 26)
                        .overlay(alignment: .bottomLeading) {
                            Button {
                                showTechnique = true
                            } label: {
                                Label("Technique", systemImage: "text.book.closed")
                                    .font(Typography.label)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .foregroundStyle(Palette.text)
                            .padding(12)
                        }
                    header
                    SetList(run: run)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .id(run.index)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutControls(run: $run, onPain: { confirmPain = true })
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .frame(maxWidth: .infinity)
                .background {
                    // Opaque, with a short fade so the sets slide under it softly.
                    Palette.ink
                        .ignoresSafeArea()
                        .shadow(color: Palette.ink, radius: 14, y: -12)
                }
        }
        .animation(Motion.smooth, value: run.index)
        .animation(Motion.snappy, value: run.stage)
        .sheet(isPresented: $showTechnique) {
            NavigationStack {
                ExerciseDetailView(exercise: run.current.exercise)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTechnique = false }
                        }
                    }
            }
        }
        .confirmationDialog("Finish the workout?", isPresented: $confirmExit, titleVisibility: .visible) {
            Button("Save and finish") {
                store.save(run)
                dismiss()
            }
            Button("Leave without saving", role: .destructive) { dismiss() }
        } message: {
            Text("What you've done so far counts if you save.")
        }
        .confirmationDialog("Does it hurt?", isPresented: $confirmPain, titleVisibility: .visible) {
            Button("Skip this exercise", role: .destructive) {
                let repeated = run.current.hurtBefore || run.current.replaces != nil
                run.reportPain(at: .now)
                if repeated { showDoctor = true }
            }
            Button("Finish the workout") {
                run.reportPain(at: .now)
                store.save(run)
                dismiss()
            }
        } message: {
            Text("Stop. We'll skip this exercise and offer a swap next time. Sharp pain, pain in a joint, dizziness, chest pain or numbness: finish the workout.")
        }
        .alert("The pain came back", isPresented: $showDoctor) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("It hurt on this move and on its swap. See a doctor before you do it again.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                if run.hasProgress { confirmExit = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.text)
                    .frame(width: 40, height: 40)
                    .background(Palette.raised, in: Circle())
            }
            .accessibilityLabel(Text("Finish the workout"))
            HStack(spacing: 4) {
                ForEach(run.plan.exercises.indices, id: \.self) { i in
                    Capsule()
                        .fill(i < run.index ? Palette.accent : i == run.index ? Palette.text : Palette.raised)
                        .frame(height: 5)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Exercise \(run.index + 1) of \(run.plan.exercises.count)"))
            TimelineView(.periodic(from: run.started, by: 1)) { context in
                Text(Duration.seconds(context.date.timeIntervalSince(run.started)).formatted(.time(pattern: .minuteSecond)))
                    .font(Typography.numbers)
                    .foregroundStyle(Palette.secondary)
                    .frame(minWidth: 48, alignment: .trailing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var header: some View {
        let current = run.current
        return VStack(alignment: .leading, spacing: 8) {
            Eyebrow("\(run.plan.kind.title) · \(run.index + 1)/\(run.plan.exercises.count)")
            Text(current.exercise.name)
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(current.prescription.summary) · \(current.exercise.muscleLine)")
                .font(Typography.caption)
                .foregroundStyle(Palette.secondary)
            if let replaced = current.replaces {
                Note(icon: "arrow.triangle.swap", text: String(localized: "Instead of \(Exercise.with(replaced).name): it hurt last time."))
            }
            if current.hurtBefore {
                Note(icon: "cross.case", text: String(localized: "This hurt before. If it hurts again, stop and see a doctor."), warning: true)
            }
            if run.isCalibrating {
                Note(icon: "scalemass", text: String(localized: "First time: we'll find your weight. After each set, say how many more reps you could have done."))
            }
        }
    }
}

/// A small line of advice with an icon.
struct Note: View {
    let icon: String
    let text: String
    var warning = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(warning ? Palette.accent : Palette.level(1))
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .card(cornerRadius: 16, fill: warning ? Palette.accent.opacity(0.1) : Palette.surface)
    }
}

/// The sets of the current exercise: done, now and to come.
private struct SetList: View {
    let run: WorkoutRun

    var body: some View {
        let unit = run.current.prescription.unit
        let hasWeight = run.current.exercise.hasWeight
        VStack(spacing: 0) {
            ForEach(0..<run.setCount, id: \.self) { i in
                let done = i < run.sets.count
                let now = i == run.sets.count && run.stage != .feeling
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(done ? Palette.accent : now ? Palette.text : Palette.raised)
                            .frame(width: 30, height: 30)
                        if done {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(i + 1)")
                                .font(Typography.numbers)
                                .foregroundStyle(now ? Palette.ink : Palette.secondary)
                        }
                    }
                    let set = done ? run.sets[i] : SetRecord(weight: run.weight, reps: run.current.targetReps)
                    Text(hasWeight ? "\(Format.kg(set.weight)) × \(Format.reps(set.reps, unit))" : Format.reps(set.reps, unit))
                        .font(Typography.label)
                        .foregroundStyle(done || now ? Palette.text : Palette.tertiary)
                    Spacer()
                    if i >= run.current.prescription.sets {
                        Text("Trial set")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .card(cornerRadius: 20)
    }
}
