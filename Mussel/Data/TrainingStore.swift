import Foundation
import Observation

/// The training log, saved as a JSON file in Application Support. On the device only.
@MainActor @Observable
final class TrainingStore {
    private(set) var log: TrainingLog

    @ObservationIgnored private let url: URL

    init(url: URL = TrainingStore.defaultURL) {
        self.url = url
        #if DEBUG
        if Debug.reset { try? FileManager.default.removeItem(at: url) }
        #endif
        if let data = try? Data(contentsOf: url), let log = try? Self.decoder.decode(TrainingLog.self, from: data) {
            self.log = log
        } else {
            log = TrainingLog()
        }
    }

    func nextWorkout(for settings: Settings, on date: Date = .now) -> PlannedWorkout {
        Coach.plan(log, daysPerWeek: settings.daysPerWeek, unavailable: settings.unavailableExercises, on: date)
    }

    /// Saves a finished or stopped workout and says what changes next time.
    @discardableResult
    func save(_ run: WorkoutRun, at date: Date = .now) -> SavedWorkout {
        let record = run.record(at: date)
        let before = log
        log = Coach.record(record, plan: run.plan, into: log)
        persist()
        return SavedWorkout(record: record, nextTime: Coach.nextTime(after: record, before: before, after: log))
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.encoder.encode(log).write(to: url, options: .atomic)
        } catch {
            assertionFailure("Couldn't save the training log: \(error)")
        }
    }

    nonisolated static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "training.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

struct SavedWorkout {
    let record: WorkoutRecord
    let nextTime: [NextTime]
}
