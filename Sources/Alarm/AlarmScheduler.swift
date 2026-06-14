import ActivityKit
import AlarmKit
import AppIntents
import Foundation
import SwiftUI

/// Thin wrapper around AlarmKit's `AlarmManager`. Translates our `Alarm` model into an
/// `AlarmConfiguration` and keeps the system's scheduled alarms in sync with the store.
///
/// `AlarmManager` is a non-Sendable class with nonisolated `async` methods, so this wrapper
/// is intentionally NOT actor-isolated and holds no state — it grabs `AlarmManager.shared`
/// locally inside each call so the manager never crosses an actor boundary (which Swift 6
/// would flag as a data race). The type itself is `Sendable` so `AlarmStore` can hold it.
final class AlarmScheduler: Sendable {
    typealias WakeConfiguration = AlarmManager.AlarmConfiguration<WakeMetadata>

    // MARK: - Authorization

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .notDetermined:
            do {
                return try await manager.requestAuthorization() == .authorized
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Sync

    /// Schedule the alarm if it is enabled, otherwise make sure it is cancelled.
    func sync(_ alarm: Alarm) async {
        guard alarm.isEnabled else {
            await cancel(alarm.id)
            return
        }
        guard await requestAuthorizationIfNeeded() else { return }
        do {
            let config = makeConfiguration(for: alarm)
            // Re-scheduling with the same id replaces the existing alarm.
            _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
        } catch {
            print("LoudWake: failed to schedule alarm \(alarm.id): \(error)")
        }
    }

    func cancel(_ id: UUID) async {
        do {
            try AlarmManager.shared.cancel(id: id)
        } catch {
            // Cancelling an unknown id is not fatal.
        }
    }

    /// Called by the in-app challenge once it is solved.
    func stop(_ id: UUID) async {
        do {
            try AlarmManager.shared.stop(id: id)
        } catch {
            print("LoudWake: failed to stop alarm \(id): \(error)")
        }
        FiringState.clear()
    }

    // MARK: - Configuration building

    private func makeConfiguration(for alarm: Alarm) -> WakeConfiguration {
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .secondary,
            systemImageName: "stop.fill"
        )

        // The prominent action: open the app to solve the challenge.
        let solveButton = AlarmButton(
            text: "Solve to dismiss",
            textColor: .white,
            systemImageName: "brain.head.profile"
        )

        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarm.label),
            stopButton: stopButton,
            secondaryButton: solveButton,
            secondaryButtonBehavior: .custom // pairs with `secondaryIntent` below
        )

        let metadata = WakeMetadata(
            label: alarm.label,
            challengeSummary: Self.challengeSummary(alarm.challenge)
        )

        let attributes = AlarmAttributes<WakeMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: metadata,
            tintColor: Color.accentColor
        )

        // `.alarm(...)` is AlarmKit's convenience factory for a clock-style alarm.
        return WakeConfiguration.alarm(
            schedule: schedule(for: alarm),
            attributes: attributes,
            secondaryIntent: OpenChallengeIntent(alarmID: alarm.id),
            sound: sound(for: alarm)
        )
    }

    // NOTE: fully qualified as `AlarmKit.Alarm` because our own model type is also named
    // `Alarm`; without the module prefix Swift resolves to the wrong `Alarm`.
    private func schedule(for alarm: Alarm) -> AlarmKit.Alarm.Schedule {
        let time = AlarmKit.Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute)
        let recurrence: AlarmKit.Alarm.Schedule.Relative.Recurrence =
            alarm.repeatDays.isEmpty ? .never : .weekly(alarm.repeatDays.map(Self.localeWeekday))
        return .relative(.init(time: time, repeats: recurrence))
    }

    private func sound(for alarm: Alarm) -> AlertConfiguration.AlertSound {
        // `AlertConfiguration.AlertSound` comes from ActivityKit. Custom sound files are
        // bundled in the app and referenced by file name.
        .named("\(alarm.soundName).caf")
    }

    private static func localeWeekday(_ day: Weekday) -> Locale.Weekday {
        switch day {
        case .sunday: .sunday
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        }
    }

    static func challengeSummary(_ config: ChallengeConfig) -> String {
        let names = config.kinds.map(\.title).joined(separator: " + ")
        return "\(names) · \(config.difficulty.title)"
    }
}
