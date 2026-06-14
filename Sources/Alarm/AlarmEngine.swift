import Foundation
import Observation

/// Coordinates the hybrid alarm behavior:
/// - keeps the app alive in the background (`KeepAliveAudioController`)
/// - polls the alarm schedule and, when one is due, takes over with the unstoppable loud
///   loop and drives the in-app challenge (`firingAlarmID` → `RingingView`)
/// - also picks up alarms surfaced by AlarmKit's "Solve to dismiss" intent (`FiringState`)
///
/// AlarmKit still schedules the real system alarm as a reliable backstop; if iOS has killed
/// the app, that system alert is what fires. While the app is alive, this engine is what
/// makes the alarm impossible to silence without solving the challenge.
@MainActor
@Observable
final class AlarmEngine {
    /// The alarm currently ringing and awaiting its challenge. Drives the blocking UI.
    var firingAlarmID: UUID?

    private let keepAlive = KeepAliveAudioController()
    private let loudAudio = AlarmAudioController()
    private let vibration = VibrationController()
    private var timer: Timer?
    private var handledOccurrences: Set<String> = []
    private weak var store: AlarmStore?

    func start(store: AlarmStore) {
        self.store = store
        keepAlive.start()
        refresh()
        timer?.invalidate()
        // Poll every few seconds; while kept alive, this fires in the background too.
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer.tolerance = 1
        self.timer = timer
    }

    /// Re-check immediately (call when the app becomes active).
    func refresh() {
        if firingAlarmID == nil, let external = FiringState.firingAlarmID {
            beginFiring(external)
        }
        tick()
    }

    private func tick() {
        guard firingAlarmID == nil else { return }

        // An alarm handed off by the AlarmKit intent takes priority.
        if let external = FiringState.firingAlarmID {
            beginFiring(external)
            return
        }

        guard let store else { return }
        let now = Date()
        for alarm in store.alarms where alarm.isEnabled && alarm.matches(now) {
            let key = alarm.occurrenceKey(for: now)
            guard !handledOccurrences.contains(key) else { continue }
            handledOccurrences.insert(key)
            beginFiring(alarm.id)
            return
        }
    }

    private func beginFiring(_ id: UUID) {
        guard firingAlarmID == nil else { return }
        firingAlarmID = id
        FiringState.begin(id)
        handledOccurrences.insert((store?.alarm(with: id) ?? Alarm()).occurrenceKey(for: Date()))
        let sound = store?.alarm(with: id)?.soundName ?? AlarmSound.defaultName
        loudAudio.start(soundName: sound)   // works in foreground AND background
        vibration.start()                   // volume-independent: can't be muted
    }

    /// Stop the noise the instant the challenge is solved (before the success moment).
    func silence() {
        loudAudio.stop()
        vibration.stop()
    }

    /// Clear the firing state once the success moment is over — dismisses the blocking UI.
    func finish(_ id: UUID) {
        silence()
        store?.stopFiring(id)               // stops the AlarmKit backstop + disables one-offs
        FiringState.clear()
        firingAlarmID = nil
        keepAlive.start()                   // re-establish keep-alive for the next alarm
    }
}
