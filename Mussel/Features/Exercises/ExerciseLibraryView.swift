import SwiftUI

/// Every exercise and machine in the app, grouped by body part, each one playing its demo.
struct ExerciseLibraryView: View {
    @State private var filter = KitFilter.all
    @State private var query = ""

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let groups = grouped
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                filterBar
                ForEach(groups, id: \.group) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Eyebrow(section.group.name)
                            Spacer()
                            Text("\(section.exercises.count)")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.tertiary)
                        }
                        .padding(.horizontal, 4)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.exercises) { exercise in
                                NavigationLink(value: exercise.id) {
                                    ExerciseCard(exercise: exercise)
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }
                }
                if groups.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .screenBackground()
        .navigationTitle("Exercises")
        .searchable(text: $query, prompt: Text("Machine or muscle"))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(KitFilter.allCases, id: \.self) { kit in
                    Button {
                        withAnimation(Motion.snappy) { filter = kit }
                    } label: {
                        Text(kit.name)
                            .font(Typography.label)
                            .foregroundStyle(filter == kit ? Palette.ink : Palette.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(filter == kit ? Palette.text : Palette.raised, in: Capsule())
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
        .sensoryFeedback(Haptics.select, trigger: filter)
    }

    private var grouped: [(group: MuscleGroup, exercises: [Exercise])] {
        let matching = ExerciseID.allCases.map { Exercise.with($0) }.filter { exercise in
            filter.includes(exercise.equipment) && matches(exercise)
        }
        let byGroup = Dictionary(grouping: matching) { $0.muscles[0].group }
        return MuscleGroup.allCases.compactMap { group in
            guard let list = byGroup[group], !list.isEmpty else { return nil }
            return (group, list.sorted { $0.level < $1.level })
        }
    }

    private func matches(_ exercise: Exercise) -> Bool {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return true }
        let haystack = [exercise.name, exercise.equipment.name] + exercise.muscles.map(\.name) + [exercise.muscles[0].group.name]
        return haystack.contains { $0.localizedStandardContains(text) }
    }
}

/// The kinds of kit to browse by.
enum KitFilter: CaseIterable {
    case all, machines, cables, dumbbells, barbell, bodyweight

    var name: String {
        switch self {
        case .all: String(localized: "All")
        case .machines: String(localized: "Machines")
        case .cables: String(localized: "Cables")
        case .dumbbells: String(localized: "Dumbbells")
        case .barbell: String(localized: "Barbell")
        case .bodyweight: String(localized: "Bodyweight")
        }
    }

    func includes(_ equipment: Equipment) -> Bool {
        switch self {
        case .all: true
        case .machines: [.machine, .plateLoaded, .assisted, .smith].contains(equipment)
        case .cables: equipment == .cable
        case .dumbbells: equipment == .dumbbell
        case .barbell: equipment == .barbell
        case .bodyweight: equipment == .bodyweight
        }
    }
}
