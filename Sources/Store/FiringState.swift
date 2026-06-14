import Foundation

/// Tracks which alarm (if any) is currently firing and awaiting its challenge.
///
/// Written by `OpenChallengeIntent` when the user taps "Solve to dismiss" on the
/// AlarmKit alert, and read by the app on activation to present the blocking
/// `RingingView`. Backed by App-Group `UserDefaults` so it survives the hop from the
/// intent into the app process.
enum FiringState {
    private static let key = "firingAlarmID"

    /// The alarm id currently demanding a challenge, or nil if none.
    static var firingAlarmID: UUID? {
        get {
            guard let raw = AppGroup.defaults.string(forKey: key) else { return nil }
            return UUID(uuidString: raw)
        }
        set {
            if let id = newValue {
                AppGroup.defaults.set(id.uuidString, forKey: key)
            } else {
                AppGroup.defaults.removeObject(forKey: key)
            }
        }
    }

    static func begin(_ id: UUID) { firingAlarmID = id }
    static func clear() { firingAlarmID = nil }
}
