import AudioToolbox
import Foundation

/// Continuous vibration while an alarm is firing.
///
/// This is the part of "you can't silence it" that actually holds on iOS: the volume buttons
/// and the silent switch do NOT affect vibration, and there is no public API to lock output
/// volume. So even if the user mutes the audio, the phone keeps buzzing until the challenge
/// is solved.
@MainActor
final class VibrationController {
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let timer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        timer.tolerance = 0.2
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
