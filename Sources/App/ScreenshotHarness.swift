#if DEBUG
import SwiftUI

/// Renders individual screens deterministically for App Store screenshots. Activated only
/// when the app is launched with the `SCREENSHOT` environment variable (DEBUG builds only),
/// so it never affects normal use or ships in release.
struct ScreenshotHarness: View {
    let screen: String

    @State private var store = AlarmStore(previewAlarms: SampleData.alarms)
    @State private var engine = AlarmEngine()

    var body: some View {
        content
            .environment(store)
            .environment(engine)
            .preferredColorScheme(.dark)
            .tint(Theme.accent)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case "list":
            NavigationStack { AlarmListView() }
        case "edit":
            AlarmEditView(alarm: SampleData.editAlarm) { _ in }
        case "math":
            RingingChrome { MathChallengeView(difficulty: .hard, onPass: {}) }
        case "typing":
            RingingChrome { TypingChallengeView(difficulty: .hard, onPass: {}, autofocus: false) }
        case "success":
            ZStack { ringingBackground; SuccessView() }
        default:
            NavigationStack { AlarmListView() }
        }
    }
}

/// Replicates the live ringing screen's chrome around an arbitrary challenge view.
private struct RingingChrome<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ringingBackground
            VStack(spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("6:30 AM")
                        .font(Theme.displayFont(28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Wake up")
                        .font(Theme.displayFont(15, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer(minLength: 0)
                }
                content.frame(maxHeight: .infinity)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 14)
        }
    }
}

private var ringingBackground: some View {
    LinearGradient(
        colors: [Theme.background, Color(red: 0.16, green: 0.05, blue: 0.02)],
        startPoint: .top, endPoint: .bottom
    )
    .ignoresSafeArea()
}

enum SampleData {
    static let alarms: [Alarm] = [
        Alarm(hour: 6, minute: 30, label: "Wake up",
              repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
              soundName: "siren_loud",
              challenge: ChallengeConfig(kinds: [.math], difficulty: .hard, repsPerKind: 3),
              isEnabled: true),
        Alarm(hour: 5, minute: 45, label: "Gym",
              repeatDays: [.monday, .wednesday, .friday],
              soundName: "klaxon",
              challenge: ChallengeConfig(kinds: [.shake, .math], difficulty: .medium, repsPerKind: 2),
              isEnabled: true),
        Alarm(hour: 8, minute: 0, label: "Weekend reset",
              repeatDays: [.saturday, .sunday],
              soundName: "rising_beep",
              challenge: ChallengeConfig(kinds: [.typing], difficulty: .hard, repsPerKind: 1),
              isEnabled: false),
    ]

    static let editAlarm = Alarm(
        hour: 6, minute: 30, label: "Wake up",
        repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        soundName: "siren_loud",
        challenge: ChallengeConfig(kinds: [.math, .typing], difficulty: .hard, repsPerKind: 3),
        isEnabled: true
    )
}
#endif
