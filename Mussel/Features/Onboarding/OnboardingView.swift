import SwiftUI

/// Welcome, then six short questions, then the program, ready. Every answer is saved as it's
/// given and can be changed later in the profile.
struct OnboardingView: View {
    enum Step: Int, CaseIterable {
        case welcome, about, goal, health, schedule, gym, ready
    }

    @Environment(Settings.self) private var settings
    @Environment(TrainingStore.self) private var store
    @State private var step = Step.welcome
    @State private var forward = true
    @State private var appeared = false

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            if step != .welcome {
                topBar
                    .transition(.opacity)
            }
            ZStack {
                page(settings: $settings)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .frame(maxHeight: .infinity)
            Button(buttonTitle) { next() }
                .buttonStyle(.capsule())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.4)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .sensoryFeedback(Haptics.tap, trigger: step)
        }
        .centered(maxWidth: 560)
        .screenBackground()
        .onChange(of: settings.sex) { _, sex in
            // The focus question comes pre-answered with what most people pick; it can be changed.
            settings.focus = Focus.suggested(for: sex)
        }
        #if DEBUG
        .onAppear { if let debug = Debug.onboardingStep.flatMap(Step.init) { step = debug } }
        #endif
    }

    // MARK: Pages

    @ViewBuilder
    private func page(settings: Bindable<Settings>) -> some View {
        switch step {
        case .welcome:
            welcome
        case .about:
            QuestionPage(title: String(localized: "A little about you"), subtitle: String(localized: "It shapes your program. Your weight is only for tracking progress, so you can skip it.")) {
                AboutYou(sex: settings.sex, age: settings.age, bodyWeight: settings.bodyWeight, experience: settings.experience)
            }
        case .goal:
            QuestionPage(title: String(localized: "What brings you to the gym?"), subtitle: String(localized: "Pick the one that matters most.")) {
                VStack(alignment: .leading, spacing: 22) {
                    GoalPicker(goal: settings.goal)
                    VStack(spacing: 10) {
                        FieldLabel(text: String(localized: "What to build first"))
                        FocusPicker(focus: settings.focus)
                    }
                }
            }
        case .health:
            QuestionPage(title: String(localized: "Anything from this list?"), subtitle: String(localized: "Tick what applies. If nothing does, just go on.")) {
                HealthChecklist(flags: settings.health)
            }
        case .schedule:
            QuestionPage(title: String(localized: "How much can you train?"), subtitle: String(localized: "You can change it any time in your profile.")) {
                ScheduleFields(days: settings.daysPerWeek, minutes: settings.sessionMinutes)
            }
        case .gym:
            QuestionPage(title: String(localized: "What does your gym have?"), subtitle: String(localized: "Tap what's missing and the program will use swaps. Not sure? Leave everything on; the «Machine taken» button helps on the day.")) {
                KitGrid(missing: settings.missingKit)
            }
        case .ready:
            ReadyPage(plan: store.nextWorkout(for: self.settings), settings: self.settings)
        }
    }

    private static let showcase: [ExerciseID] = [.legPress, .latPulldown, .chestPress, .gobletSquat]

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(Self.showcase.enumerated()), id: \.element) { index, id in
                    DemoView(demo: Demos.of(id), framesPerSecond: 30)
                        .aspectRatio(1, contentMode: .fit)
                        .demoStage(cornerRadius: 22)
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                        .animation(Motion.smooth.delay(Double(index) * 0.08), value: appeared)
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
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(Motion.smooth.delay(0.35), value: appeared)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
        .onAppear { appeared = true }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.text)
                    .frame(width: 40, height: 40)
                    .background(Palette.raised, in: Circle())
            }
            .accessibilityLabel(Text("Previous step"))
            HStack(spacing: 4) {
                ForEach(1..<Step.allCases.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= step.rawValue ? Palette.accent : Palette.raised)
                        .frame(height: 5)
                }
            }
            .animation(Motion.smooth, value: step)
            .accessibilityElement()
            .accessibilityLabel(Text("Step \(step.rawValue) of \(Step.allCases.count - 1)"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: Flow

    private var buttonTitle: String {
        switch step {
        case .welcome: String(localized: "Get started")
        case .ready: String(localized: "Let's go")
        default: String(localized: "Next")
        }
    }

    private var canContinue: Bool {
        step != .goal || settings.goal != nil
    }

    private func next() {
        guard let following = Step(rawValue: step.rawValue + 1) else {
            settings.isOnboarded = true
            return
        }
        forward = true
        withAnimation(Motion.smooth) { step = following }
    }

    private func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        forward = false
        withAnimation(Motion.smooth) { step = previous }
    }
}

/// A question: a big title, a line under it and the answers, scrolling if they're tall.
private struct QuestionPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(Typography.largeTitle)
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// The end of onboarding: the plan in a few lines and the first workout.
private struct ReadyPage: View {
    let plan: PlannedWorkout
    let settings: Settings

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Palette.accentGradient)
                        .symbolEffect(.bounce, value: appeared)
                    Text("Your program is ready")
                        .font(Typography.largeTitle)
                        .foregroundStyle(Palette.text)
                    if let goal = settings.goal {
                        Text(goal.title)
                            .font(Typography.body)
                            .foregroundStyle(Palette.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    point("calendar", String(localized: "12 weeks: machines, then dumbbells, then the barbell."))
                    point("scalemass", String(localized: "On the first workout we'll find your weights together."))
                    point("hand.thumbsup", String(localized: "After each exercise: easy, normal or hard. The app takes it from there."))
                }
                WhyCard(notes: settings.program.notes)
                firstWorkout
                if !settings.health.isEmpty || settings.isMinor {
                    Note(icon: "stethoscope", text: String(localized: "Remember: see a doctor and start with a coach before training on your own."), warning: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { appeared = true }
    }

    private var firstWorkout: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(String(localized: "Your first workout"))
            Text(plan.kind.title)
                .font(Typography.title)
                .foregroundStyle(Palette.text)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        DemoView(demo: item.exercise.demo, framesPerSecond: 30)
                            .aspectRatio(1, contentMode: .fit)
                            .demoStage(cornerRadius: 14)
                        Text(item.exercise.name)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2, reservesSpace: true)
                    }
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)
                    .animation(Motion.smooth.delay(0.15 + Double(index) * Motion.stagger), value: appeared)
                }
            }
        }
        .padding(16)
        .card(cornerRadius: 26)
    }

    private func point(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 26)
            Text(text)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension View {
    /// No wider than `width`, centred in whatever room there is (iPad).
    func centered(maxWidth width: CGFloat) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }
}
