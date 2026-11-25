import SwiftUI

/// The workout whose turn it is, with the button that starts it.
struct NextWorkoutCard: View {
    let plan: PlannedWorkout
    let lastWorkout: Date?
    let onStart: () -> Void

    private var details: String {
        let week = String(localized: "week \(plan.week)")
        let count = String(localized: "\(plan.exercises.count) exercises")
        return [Program.phaseName(plan.phase), week, count].joined(separator: " · ")
    }

    /// "today", "yesterday", "3 days ago": whole days, not seconds.
    private func daysAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(from: DateComponents(day: -Coach.days(from: date, to: .now, .current)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(String(localized: "Next workout"))
                    Text(plan.kind.title)
                        .font(Typography.title)
                        .foregroundStyle(Palette.text)
                    Text(details)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondary)
                }
                Spacer()
                if let lastWorkout {
                    Text("Last: \(daysAgo(lastWorkout))")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiary)
                }
            }
            HStack(spacing: 6) {
                ForEach(plan.exercises, id: \.prescription.exercise) { item in
                    DemoView(demo: item.exercise.demo, isPlaying: false)
                        .aspectRatio(1, contentMode: .fit)
                        .demoStage(cornerRadius: 10)
                }
            }
            if let comeback = plan.comeback {
                Note(icon: "arrow.uturn.backward", text: comeback == .restart
                    ? String(localized: "Welcome back! After a month off the weights are \(20)% lighter and the phase starts over.")
                    : String(localized: "Welcome back! After the break the weights are \(10)% lighter."))
            }
            Button(action: onStart) {
                Label("Start workout", systemImage: "play.fill")
            }
            .buttonStyle(.capsule())
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Palette.accent.opacity(0.16), Palette.surface], startPoint: .topLeading, endPoint: .bottom))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Palette.accent.opacity(0.35), lineWidth: 1)
        }
    }
}
