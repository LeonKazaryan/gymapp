import SwiftUI

struct RootView: View {
    @Environment(Settings.self) private var settings

    var body: some View {
        ZStack {
            if settings.isOnboarded {
                MainView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(Motion.smooth, value: settings.isOnboarded)
    }
}

struct MainView: View {
    enum Section: Hashable {
        case program, exercises
    }

    @State private var section = Section.program
    @State private var programPath: [ExerciseID] = []
    @State private var exercisesPath: [ExerciseID] = []

    var body: some View {
        TabView(selection: $section) {
            Tab("Program", systemImage: "calendar", value: Section.program) {
                NavigationStack(path: $programPath) {
                    ProgramView()
                        .exerciseDestinations()
                }
            }
            Tab("Exercises", systemImage: "dumbbell.fill", value: Section.exercises) {
                NavigationStack(path: $exercisesPath) {
                    ExerciseLibraryView()
                        .exerciseDestinations()
                }
            }
        }
        #if DEBUG
        .onAppear {
            switch Debug.screen {
            case "library":
                section = .exercises
            case "exercise":
                section = .exercises
                exercisesPath = [Debug.exercise ?? .legPress]
            default:
                break
            }
        }
        #endif
    }
}

extension View {
    /// Tapping an exercise anywhere opens its page.
    func exerciseDestinations() -> some View {
        navigationDestination(for: ExerciseID.self) { id in
            ExerciseDetailView(exercise: .with(id))
        }
    }
}
