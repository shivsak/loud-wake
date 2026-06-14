import SwiftUI

/// A full preview of what an alarm will be like: it plays the chosen sound, vibrates, and
/// runs the real challenge flow — but, unlike a real alarm, it can be exited at any time.
struct ChallengePreviewView: View {
    let alarm: Alarm
    @Environment(\.dismiss) private var dismiss

    @State private var audio = AlarmAudioController()
    @State private var vibration = VibrationController()
    @State private var done = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Color(red: 0.16, green: 0.05, blue: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Label("Preview", systemImage: "eye.fill")
                        .font(Theme.displayFont(14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Button {
                        stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if done {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.success)
                        Text("That's the experience")
                            .font(Theme.displayFont(22, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("A real alarm can't be exited until solved.")
                            .font(Theme.displayFont(14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    ChallengeFlowView(config: alarm.challenge) {
                        stop()
                        withAnimation(Theme.spring) { done = true }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 14)
        }
        .onAppear {
            audio.start(soundName: alarm.soundName)
            vibration.start()
        }
        .onDisappear(perform: stop)
    }

    private func stop() {
        audio.stop()
        vibration.stop()
    }
}
