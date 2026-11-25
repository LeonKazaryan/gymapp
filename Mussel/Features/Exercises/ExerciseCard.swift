import SwiftUI

/// An exercise in the library grid: its demo playing, the name and the kit it needs.
struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DemoView(demo: exercise.demo, framesPerSecond: 30)
                .aspectRatio(1, contentMode: .fit)
                .demoStage(cornerRadius: 18)
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(Typography.label)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Palette.level(exercise.level))
                        .frame(width: 6, height: 6)
                    Text(exercise.equipment.name)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .padding(8)
        .card(cornerRadius: 24)
        .accessibilityElement(children: .combine)
    }
}

/// An exercise as a line in a list: a small demo, the name and what to do.
struct ExerciseRow: View {
    let exercise: Exercise
    var detail: String?

    var body: some View {
        HStack(spacing: 14) {
            DemoView(demo: exercise.demo, framesPerSecond: 30)
                .frame(width: 64, height: 64)
                .demoStage(cornerRadius: 14)
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(Typography.label)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.leading)
                Text(exercise.muscleLine)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let detail {
                Text(detail)
                    .font(Typography.numbers)
                    .foregroundStyle(Palette.text)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
