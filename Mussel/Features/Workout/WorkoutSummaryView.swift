import SwiftUI

/// The end of a workout: what was done and what changes next time.
struct WorkoutSummaryView: View {
    let saved: SavedWorkout
    let onDone: () -> Void

    var body: some View {
        let record = saved.record
        let done = record.exercises.filter { $0.outcome == .done }
        let sets = done.reduce(0) { $0 + $1.sets.count }
        let volume = done.flatMap(\.sets).reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Palette.accentGradient)
                        .symbolEffect(.bounce, value: true)
                    Text("\(record.kind.title) done")
                        .font(Typography.largeTitle)
                        .foregroundStyle(Palette.text)
                }
                .padding(.top, 24)
                HStack(spacing: 10) {
                    tile(Duration.seconds(record.duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)), String(localized: "time"))
                    tile("\(sets)", String(localized: "sets"))
                    tile(Format.kg(volume), String(localized: "lifted"))
                }
                if !saved.nextTime.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(String(localized: "Next time"))
                        VStack(spacing: 0) {
                            ForEach(Array(saved.nextTime.enumerated()), id: \.offset) { index, item in
                                row(item)
                                if index < saved.nextTime.count - 1 {
                                    Divider().overlay(Palette.hairline)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .card(cornerRadius: 20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done", action: onDone)
                .buttonStyle(.capsule())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Palette.ink.ignoresSafeArea())
        }
    }

    private func tile(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy).monospacedDigit())
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card(cornerRadius: 18)
    }

    private func row(_ item: NextTime) -> some View {
        let (icon, color, text) = describe(item.change)
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(Exercise.with(item.exercise).name)
                    .font(Typography.label)
                    .foregroundStyle(Palette.text)
                Text(text)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private func describe(_ change: NextTime.Change) -> (String, Color, String) {
        switch change {
        case let .found(weight):
            ("scalemass.fill", Palette.level(1), String(localized: "Your working weight: \(Format.kg(weight))"))
        case let .heavier(from, to):
            ("arrow.up.circle.fill", Palette.accent, "\(Format.kg(from)) → \(Format.kg(to))")
        case let .lighter(from, to):
            ("arrow.down.circle.fill", Palette.secondary, "\(Format.kg(from)) → \(Format.kg(to))")
        case let .moreReps(reps, unit):
            ("plus.circle.fill", Palette.mint, String(localized: "Aim for \(Format.reps(reps, unit))"))
        case .same:
            ("equal.circle.fill", Palette.tertiary, String(localized: "Same weight, same reps"))
        case .swap:
            ("arrow.triangle.swap", Palette.accent, String(localized: "A swap next time"))
        }
    }
}
