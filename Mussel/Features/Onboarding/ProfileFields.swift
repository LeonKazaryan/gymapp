import SwiftUI

// The questions about the person, shared by the onboarding pages and the profile screen.

/// A big card that can be chosen: a picture on the left, words, and a check.
struct ChoiceCard<Picture: View>: View {
    let title: String
    var detail: String?
    let selected: Bool
    @ViewBuilder let picture: Picture
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                picture
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.text)
                    if let detail {
                        Text(detail)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Palette.accent : Palette.tertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(14)
            .background(selected ? Palette.accent.opacity(0.12) : Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(selected ? Palette.accent : Palette.hairline, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Why they came to the gym, each goal pictured by an exercise.
struct GoalPicker: View {
    @Binding var goal: Goal?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Goal.allCases, id: \.self) { option in
                ChoiceCard(title: option.title, detail: option.detail, selected: goal == option) {
                    DemoView(demo: Demos.of(option.picture), framesPerSecond: 30)
                        .frame(width: 72, height: 72)
                        .demoStage(cornerRadius: 16)
                } action: {
                    withAnimation(Motion.snappy) { goal = option }
                }
            }
        }
        .sensoryFeedback(Haptics.select, trigger: goal)
    }
}

/// 2, 3 or 4 days a week.
struct DaysChoice: View {
    @Binding var days: Int

    var body: some View {
        VStack(spacing: 10) {
            option(2, String(localized: "Twice"), String(localized: "When time is short: two full-body workouts."))
            option(3, String(localized: "Three times"), String(localized: "Recommended: workouts A and B take turns."))
            option(4, String(localized: "Four times"), String(localized: "Upper and lower body on separate days."))
        }
        .sensoryFeedback(Haptics.select, trigger: days)
    }

    private func option(_ value: Int, _ title: String, _ detail: String) -> some View {
        ChoiceCard(title: title, detail: detail, selected: days == value) {
            Text("\(value)")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(days == value ? Palette.accent : Palette.text)
                .frame(width: 56, height: 56)
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } action: {
            withAnimation(Motion.snappy) { days = value }
        }
    }
}

/// Age and body weight on two wheels.
struct AboutFields: View {
    @Binding var age: Int?
    @Binding var bodyWeight: Double?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                wheel(String(localized: "Age")) {
                    Picker(String(localized: "Age"), selection: Binding(get: { age ?? 25 }, set: { age = $0 })) {
                        ForEach(12...80, id: \.self) { Text("\($0)").tag($0) }
                    }
                }
                wheel(String(localized: "Weight, kg")) {
                    Picker(String(localized: "Weight, kg"), selection: Binding(get: { Int(bodyWeight ?? 70) }, set: { bodyWeight = Double($0) })) {
                        ForEach(35...200, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .opacity(bodyWeight == nil ? 0.35 : 1)
                }
            }
            HStack {
                Spacer()
                Button {
                    withAnimation(Motion.snappy) { bodyWeight = bodyWeight == nil ? 70 : nil }
                } label: {
                    Label(bodyWeight == nil ? String(localized: "Add my weight") : String(localized: "Rather not say"), systemImage: bodyWeight == nil ? "plus" : "eye.slash")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondary)
                }
            }
            if (age ?? 25) < 16 {
                Note(icon: "person.2", text: String(localized: "Under 16, train with a coach nearby. Use the app for technique and let the coach pick the weights."), warning: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear { if age == nil { age = 25 } }
        .animation(Motion.snappy, value: (age ?? 25) < 16)
    }

    private func wheel(_ title: String, @ViewBuilder picker: () -> some View) -> some View {
        VStack(spacing: 0) {
            Eyebrow(title)
                .padding(.top, 14)
            picker()
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .card(cornerRadius: 22)
    }
}

/// The safety questions. Any "yes" brings up the advice to see a doctor first.
struct HealthChecklist: View {
    @Binding var flags: Set<HealthFlag>

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                ForEach(Array(HealthFlag.allCases.enumerated()), id: \.element) { index, flag in
                    let on = flags.contains(flag)
                    Button {
                        withAnimation(Motion.snappy) {
                            if on { flags.remove(flag) } else { flags.insert(flag) }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: flag.symbol)
                                .font(.body)
                                .foregroundStyle(on ? Palette.accent : Palette.secondary)
                                .frame(width: 28)
                            Text(flag.title)
                                .font(Typography.body)
                                .foregroundStyle(Palette.text)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            Image(systemName: on ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(on ? Palette.accent : Palette.tertiary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    if index < HealthFlag.allCases.count - 1 {
                        Divider().overlay(Palette.hairline).padding(.leading, 42)
                    }
                }
            }
            .padding(.horizontal, 16)
            .card(cornerRadius: 22)
            if !flags.isEmpty {
                Note(icon: "stethoscope", text: String(localized: "See a doctor first, and do your first workouts with a coach. The app can still show you the technique."), warning: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Text("The app gives training advice, not medical advice.")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sensoryFeedback(Haptics.select, trigger: flags)
    }
}

/// The machines of the program, each playing its demo. Tap the ones your gym doesn't have.
struct KitGrid: View {
    @Binding var missing: Set<GymKit>

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(GymKit.allCases, id: \.self) { kit in
                let has = !missing.contains(kit)
                Button {
                    withAnimation(Motion.snappy) {
                        if has { missing.insert(kit) } else { missing.remove(kit) }
                    }
                } label: {
                    VStack(spacing: 8) {
                        DemoView(demo: Demos.of(kit.picture), isPlaying: has, framesPerSecond: 30)
                            .aspectRatio(1, contentMode: .fit)
                            .demoStage(cornerRadius: 16)
                            .saturation(has ? 1 : 0)
                            .opacity(has ? 1 : 0.4)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: has ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, has ? Palette.accent : Palette.tertiary)
                                    .contentTransition(.symbolEffect(.replace))
                                    .padding(6)
                            }
                        Text(kit.name)
                            .font(Typography.label)
                            .foregroundStyle(has ? Palette.text : Palette.tertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .strikethrough(!has, color: Palette.tertiary)
                            .padding(.bottom, 4)
                    }
                    .padding(8)
                    .card(cornerRadius: 22)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(Text(kit.name))
                .accessibilityValue(has ? Text("In my gym") : Text("Not in my gym"))
            }
        }
        .sensoryFeedback(Haptics.select, trigger: missing)
    }
}
