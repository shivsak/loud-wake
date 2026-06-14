import AppIntents
import Foundation

/// Runs when the user taps "Solve to dismiss" on the AlarmKit alert.
///
/// It records the firing alarm in shared storage and foregrounds the app
/// (`openAppWhenRun = true`). The app then presents the blocking challenge screen.
/// Crucially it does NOT stop the alarm — only solving the challenge does that — so the
/// loud alert keeps pressuring the user until the in-app challenge is completed.
struct OpenChallengeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Solve to dismiss"
    static let openAppWhenRun = true

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            FiringState.begin(id)
        }
        return .result()
    }
}
