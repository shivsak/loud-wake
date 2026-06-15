import SwiftUI

/// The blocking wake-up screen shown when an alarm fires. It cannot be dismissed by the user
/// — only by completing every challenge. The loud loop and vibration are owned by the
/// `AlarmEngine` so they persist even before this view appears; this view runs the challenge
/// flow and tells the engine to stop once solved, then shows a short success moment.
struct RingingView: View {
    let alarmID: UUID
    @Environment(AlarmStore.self) private var store
    @Environment(AlarmEngine.self) private var engine

    @State private var solved = false

    private var alarm: Alarm? { store.alarm(with: alarmID) }
    private var config: ChallengeConfig { alarm?.challenge ?? .default }

    var body: some View {
        ZStack {
            background

            if solved {
                SuccessView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack(spacing: 14) {
                    header
                    ChallengeFlowView(config: config, onComplete: complete)
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 14)
            }
        }
        .interactiveDismissDisabled(true)
        .animation(Theme.spring, value: solved)
    }

    private var background: some View {
        LinearGradient(
            colors: [Theme.background, Color(red: 0.16, green: 0.05, blue: 0.02)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(Theme.displayFont(28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            Text(alarm?.label ?? "Wake up")
                .font(Theme.displayFont(15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func complete() {
        guard !solved else { return }
        engine.silence()                 // kill the noise immediately
        withAnimation(Theme.spring) { solved = true }
        // Let the success moment breathe, then dismiss.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            engine.finish(alarmID)
        }
    }
}

/// A brief, warm confirmation after the alarm is beaten.
struct SuccessView: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.bounce, value: appeared)
                .scaleEffect(appeared ? 1 : 0.6)
            Text("Good morning")
                .font(Theme.displayFont(34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("You're up. Have a great day.")
                .font(Theme.displayFont(16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(Theme.spring) { appeared = true } }
    }
}
