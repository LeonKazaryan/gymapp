import SwiftUI

/// Two screens: what the app is, then how many days a week.
struct OnboardingView: View {
    @Environment(Settings.self) private var settings
    @State private var step = 0
    @State private var days = 3

    var body: some View {
        ZStack {
            if step == 0 {
                welcome
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                daysChoice
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
        }
        .animation(Motion.smooth, value: step)
        .screenBackground()
    }

    // MARK: Welcome

    private static let showcase: [ExerciseID] = [.legPress, .latPulldown, .chestPress, .gobletSquat]

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Self.showcase, id: \.self) { id in
                    DemoView(demo: Demos.of(id), framesPerSecond: 30)
                        .aspectRatio(1, contentMode: .fit)
                        .demoStage(cornerRadius: 22)
                }
            }
            .padding(.top, 12)
            Spacer(minLength: 24)
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow("Mussel")
                Text("Your first 90 days in the gym")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A 12-week program from machines to the barbell, and every exercise shown so you know what to do and where.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 24)
            Button("Get started") { step = 1 }
                .buttonStyle(.capsule())
                .sensoryFeedback(Haptics.tap, trigger: step)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .centered(maxWidth: 540)
    }

    // MARK: Days

    private var daysChoice: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                step = 0
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.text)
                    .frame(width: 44, height: 44)
                    .background(Palette.raised, in: Circle())
            }
            .accessibilityLabel(Text("Previous step"))
            .padding(.top, 8)
            VStack(alignment: .leading, spacing: 10) {
                Text("How many days a week can you train?")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("You can change it any time on the program screen.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondary)
            }
            .padding(.top, 24)
            VStack(spacing: 10) {
                option(2, title: String(localized: "Twice"), detail: String(localized: "When time is short: two full-body workouts."))
                option(3, title: String(localized: "Three times"), detail: String(localized: "Recommended: workouts A and B take turns."))
                option(4, title: String(localized: "Four times"), detail: String(localized: "Upper and lower body on separate days."))
            }
            .padding(.top, 28)
            .sensoryFeedback(Haptics.select, trigger: days)
            Spacer(minLength: 24)
            Button("Start") {
                settings.daysPerWeek = days
                settings.isOnboarded = true
            }
            .buttonStyle(.capsule())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .centered(maxWidth: 540)
    }

    private func option(_ value: Int, title: String, detail: String) -> some View {
        let selected = value == days
        return Button {
            withAnimation(Motion.snappy) { days = value }
        } label: {
            HStack(spacing: 16) {
                Text("\(value)")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(selected ? Palette.accent : Palette.text)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.text)
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Palette.accent : Palette.tertiary)
            }
            .multilineTextAlignment(.leading)
            .padding(16)
            .background(selected ? Palette.accent.opacity(0.12) : Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? Palette.accent : Palette.hairline, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension View {
    /// No wider than `width`, centred in whatever room there is (iPad).
    func centered(maxWidth width: CGFloat) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }
}
