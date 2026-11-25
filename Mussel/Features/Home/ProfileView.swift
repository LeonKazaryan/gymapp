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
                    section(String(localized: "Goal")) { GoalPicker(goal: $settings.goal) }
                    section(String(localized: "About you")) { AboutFields(age: $settings.age, bodyWeight: $settings.bodyWeight) }
                    section(String(localized: "Health")) { HealthChecklist(flags: $settings.health) }
                    section(String(localized: "Days a week")) { DaysChoice(days: $settings.daysPerWeek) }
                    section(String(localized: "Your gym")) {
                        Text("Tap what's missing; the program will use swaps.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondary)
                        KitGrid(missing: $settings.missingKit)
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
