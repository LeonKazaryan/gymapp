import SwiftUI

/// The 12-week program: how many days a week, the three phases and every workout in them.
/// It's what the coaches review, so everything in it is visible at once.
struct ProgramView: View {
    @Environment(Settings.self) private var settings
    @Environment(TrainingStore.self) private var store
    @State private var phase = 0
    @State private var workout: PlannedWorkout?
    @State private var showProfile = false

    var body: some View {
        @Bindable var settings = settings
        let personal = settings.program
        let program = personal.program
        let next = store.nextWorkout(for: settings)
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                NextWorkoutCard(plan: next, lastWorkout: store.log.lastWorkout) {
                    workout = store.nextWorkout(for: settings)
                }
                WhyCard(notes: personal.notes)
                VStack(alignment: .leading, spacing: 12) {
                    DaysPicker(days: $settings.daysPerWeek)
                    Text(program.weekPlan)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
                VStack(alignment: .leading, spacing: 12) {
                    PhasePicker(selection: $phase, program: program)
                    phaseNotes(program)
                }
                ForEach(program.phases[phase].workouts, id: \.kind) { workout in
                    WorkoutCard(workout: workout)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .animation(Motion.smooth, value: phase)
            .animation(Motion.smooth, value: settings.daysPerWeek)
        }
        .screenBackground()
        .navigationTitle("Program")
        .fullScreenCover(item: $workout) { plan in
            WorkoutView(plan: plan)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel(Text("Profile"))
            }
        }
        .onChange(of: next.phase, initial: true) { _, current in
            phase = current
            #if DEBUG
            if let debug = Debug.phase { phase = debug }
            #endif
        }
        #if DEBUG
        .task {
            if Debug.screen == "workout" { workout = next }
            if Debug.screen == "profile" { showProfile = true }
        }
        #endif
    }

    private func phaseNotes(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(program.restNote(phase: phase), systemImage: "timer")
            if let note = Program.phaseNote(phase) {
                Label(note, systemImage: "info.circle")
            }
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.secondary)
        .padding(.horizontal, 4)
    }
}

/// 2, 3 or 4 training days a week.
private struct DaysPicker: View {
    @Binding var days: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach([2, 3, 4], id: \.self) { option in
                let selected = option == days
                Button {
                    withAnimation(Motion.snappy) { days = option }
                } label: {
                    VStack(spacing: 2) {
                        Text("\(option)")
                            .font(.system(.title, design: .rounded, weight: .heavy))
                        Text("times a week")
                            .font(Typography.caption)
                            .foregroundStyle(selected ? Palette.text : Palette.secondary)
                    }
                    .foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selected ? Palette.accent.opacity(0.16) : Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? Palette.accent : Palette.hairline, lineWidth: selected ? 1.5 : 1)
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(Haptics.select, trigger: days)
    }
}

/// The three 4-week phases: machines, dumbbells, barbell.
private struct PhasePicker: View {
    @Binding var selection: Int
    let program: Program

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                let selected = index == selection
                let color = Palette.level(index + 1)
                Button {
                    withAnimation(Motion.snappy) { selection = index }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule()
                            .fill(color)
                            .frame(width: 28, height: 4)
                        Text(program.phaseWeeksText(index))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                        Text(Program.phaseName(index))
                            .font(Typography.headline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(selected ? color.opacity(0.14) : Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? color : Palette.hairline, lineWidth: selected ? 1.5 : 1)
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(Haptics.select, trigger: selection)
    }
}

/// One workout of a phase with every exercise in it.
private struct WorkoutCard: View {
    let workout: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.kind.title)
                    .font(Typography.title)
                    .foregroundStyle(Palette.text)
                Text(String(localized: "\(workout.items.count) exercises") + " · " + String(localized: "\(workout.totalSets) sets"))
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 8)
            ForEach(Array(workout.items.enumerated()), id: \.offset) { index, item in
                NavigationLink(value: item.exercise) {
                    ExerciseRow(exercise: .with(item.exercise), detail: item.summary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.pressable)
                if index < workout.items.count - 1 {
                    Divider()
                        .overlay(Palette.hairline)
                        .padding(.leading, 92)
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.bottom, 8)
        .card(cornerRadius: 26)
    }
}
