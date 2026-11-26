import SwiftUI

/// The onboarding answers, all on one screen and editable. Changes apply to the next workout.
struct ProfileView: View {
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    WhyCard(notes: settings.program.notes)
                    section(String(localized: "About you")) {
                        AboutYou(sex: $settings.sex, age: $settings.age, bodyWeight: $settings.bodyWeight, experience: $settings.experience)
                    }
                    section(String(localized: "Goal")) {
                        GoalPicker(goal: $settings.goal)
                        FieldLabel(text: String(localized: "What to build first"))
                            .padding(.top, 10)
                        FocusPicker(focus: $settings.focus)
                    }
                    section(String(localized: "Health")) { HealthChecklist(flags: $settings.health) }
                    section(String(localized: "Schedule")) {
                        ScheduleFields(days: $settings.daysPerWeek, minutes: $settings.sessionMinutes)
                    }
                    section(String(localized: "Your gym")) {
                        Text("Tap what's missing; the program will use swaps.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                        KitGrid(missing: $settings.missingKit)
                    }
                    if !settings.disabledExercises.isEmpty {
                        section(String(localized: "Switched off")) {
                            VStack(spacing: 0) {
                                ForEach(settings.disabledExercises.sorted { $0.rawValue < $1.rawValue }, id: \.self) { id in
                                    HStack(spacing: 12) {
                                        Text(Exercise.with(id).name)
                                            .font(Typography.label)
                                            .foregroundStyle(Palette.text)
                                        Spacer()
                                        Button("Offer it again") {
                                            withAnimation(Motion.snappy) { _ = settings.disabledExercises.remove(id) }
                                        }
                                        .font(Typography.caption)
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 16)
                            .card(cornerRadius: 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .screenBackground()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(title)
            content()
        }
    }
}
