import Foundation
import Observation

/// Persists and observes the user's alarms. Source of truth for the alarm list UI;
/// every mutation is written to a JSON file in the shared App-Group container and
/// reconciled with AlarmKit via `AlarmScheduler`.
@MainActor
@Observable
final class AlarmStore {
    private(set) var alarms: [Alarm] = []

    private let fileURL: URL
    private let scheduler: AlarmScheduler

    init(scheduler: AlarmScheduler = AlarmScheduler()) {
        self.scheduler = scheduler
        self.fileURL = AppGroup.containerURL.appendingPathComponent("alarms.json")
        load()
    }

    // MARK: - Mutations

    func add(_ alarm: Alarm) {
        alarms.append(alarm)
        sort()
        save()
        Task { await scheduler.sync(alarm) }
    }

    func update(_ alarm: Alarm) {
        guard let idx = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[idx] = alarm
        sort()
        save()
        Task { await scheduler.sync(alarm) }
    }

    func delete(at offsets: IndexSet) {
        let removed = offsets.map { alarms[$0] }
        alarms.remove(atOffsets: offsets)
        save()
        Task {
            for alarm in removed { await scheduler.cancel(alarm.id) }
        }
    }

    func setEnabled(_ enabled: Bool, for alarm: Alarm) {
        guard let idx = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[idx].isEnabled = enabled
        save()
        let updated = alarms[idx]
        Task { await scheduler.sync(updated) }
    }

    func alarm(with id: UUID) -> Alarm? {
        alarms.first { $0.id == id }
    }

    /// Called once the in-app challenge is solved: silences the system alarm and clears
    /// the firing flag. For non-repeating alarms it also disables the entry afterwards.
    func stopFiring(_ id: UUID) {
        Task { await scheduler.stop(id) }
        if let idx = alarms.firstIndex(where: { $0.id == id }), !alarms[idx].isRepeating {
            alarms[idx].isEnabled = false
            save()
        }
    }

    /// Re-register every enabled alarm with AlarmKit (call once at launch).
    func resync() {
        let snapshot = alarms
        Task {
            await scheduler.requestAuthorizationIfNeeded()
            for alarm in snapshot { await scheduler.sync(alarm) }
        }
    }

    // MARK: - Persistence

    private func sort() {
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
            sort()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
