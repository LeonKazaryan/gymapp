import SwiftUI

/// One exercise: the demo big, what it works, how to do it, the mistake to avoid, what to do
/// when the machine is busy and where it shows up in the program.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(Settings.self) private var settings
    @State private var isPlaying = true
    @State private var isSlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                stage
                header
                howTo
                mistake
                if let alternative = exercise.alternative.map({ Exercise.with($0) }) {
                    section(String(localized: "If it's taken")) {
                        NavigationLink(value: alternative.id) {
                            ExerciseRow(exercise: alternative)
                                .padding(12)
                                .card(cornerRadius: 20)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                inProgram
                switchOff
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stage: some View {
        DemoView(demo: exercise.demo, isPlaying: isPlaying, speed: isSlow ? 0.5 : 1)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 520)
            .demoStage(cornerRadius: 28)
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 4) {
                    Button {
                        isSlow.toggle()
                    } label: {
                        Text(isSlow ? "0.5×" : "1×")
                            .font(Typography.numbers)
                            .frame(width: 48, height: 40)
                    }
                    .accessibilityLabel(isSlow ? Text("Normal speed") : Text("Slow motion"))
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 40)
                    }
                    .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
                }
                .foregroundStyle(Palette.text)
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(14)
                .sensoryFeedback(Haptics.tap, trigger: isPlaying)
                .sensoryFeedback(Haptics.tap, trigger: isSlow)
            }
            .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exercise.name)
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.text)
            FlowLayout(spacing: 8) {
                Chip(text: exercise.equipment.name, color: Palette.level(exercise.level))
                ForEach(exercise.muscles, id: \.self) { muscle in
                    Chip(text: muscle.name, color: Palette.muscle, filled: true)
                }
            }
        }
    }

    private var howTo: some View {
        section(String(localized: "How to do it")) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(exercise.technique.cues.enumerated()), id: \.offset) { index, cue in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text("\(index + 1)")
                            .font(Typography.numbers)
                            .foregroundStyle(Palette.accent)
                            .frame(width: 30, height: 30)
                            .background(Palette.accent.opacity(0.14), in: Circle())
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 6 }
                        Text(cue)
                            .font(Typography.body)
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var mistake: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(String(localized: "Main mistake"))
                Text(exercise.technique.mistake)
                    .font(Typography.body)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .card(cornerRadius: 22, fill: Palette.accent.opacity(0.09))
    }

    @ViewBuilder
    private var inProgram: some View {
        let uses = programUses
        if !uses.isEmpty {
            section(String(localized: "In your program")) {
                VStack(spacing: 0) {
                    ForEach(Array(uses.enumerated()), id: \.offset) { index, use in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Palette.level(use.phase + 1))
                                .frame(width: 8, height: 8)
                            Text("\(Program.phaseName(use.phase)) · \(use.workout.title)")
                                .font(Typography.label)
                                .foregroundStyle(Palette.text)
                            Spacer()
                            Text(use.prescription.summary)
                                .font(Typography.numbers)
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(.vertical, 12)
                        if index < uses.count - 1 {
                            Divider().overlay(Palette.hairline)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .card(cornerRadius: 20)
            }
        }
    }

    private var programUses: [(phase: Int, workout: WorkoutKind, prescription: Prescription)] {
        let program = settings.program.program
        return program.phases.enumerated().flatMap { phase, content in
            content.workouts.flatMap { workout in
                workout.items
                    .filter { $0.exercise == exercise.id }
                    .map { (phase, workout.kind, $0) }
            }
        }
    }

    /// Never offer this exercise: the program uses its swap instead.
    @ViewBuilder
    private var switchOff: some View {
        @Bindable var settings = settings
        let off = settings.disabledExercises.contains(exercise.id)
        VStack(alignment: .leading, spacing: 10) {
            if off {
                Note(icon: "eye.slash", text: String(localized: "Switched off: the program won't offer it and uses a swap instead."))
            }
            Button {
                withAnimation(Motion.snappy) {
                    if off { settings.disabledExercises.remove(exercise.id) } else { settings.disabledExercises.insert(exercise.id) }
                }
            } label: {
                Label(off ? String(localized: "Offer it again") : String(localized: "Don't offer this exercise"), systemImage: off ? "arrow.uturn.backward" : "eye.slash")
            }
            .buttonStyle(.capsule(.subtle))
            .sensoryFeedback(Haptics.tap, trigger: off)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(title)
            content()
        }
    }
}
