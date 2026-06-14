import AVFoundation
import Foundation

/// Plays a loud, looping alarm tone while the in-app challenge is on screen.
///
/// AlarmKit silences its own system sound once the alert is handed off to the app, so we
/// keep our own audio going — at full volume, ignoring the silent switch — until the
/// challenge is solved. Uses the `.playback` category so it sounds even when muted.
@MainActor
final class AlarmAudioController {
    private var player: AVAudioPlayer?

    /// Start blaring the given bundled sound on loop. Safe to call repeatedly.
    func start(soundName: String) {
        guard player == nil else { return }

        configureSession()

        guard let url = Self.url(for: soundName) else {
            print("LoudWake: missing sound \(soundName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1   // loop forever
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("LoudWake: failed to play \(soundName): \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        // Intentionally do NOT deactivate the shared session — the keep-alive loop relies on
        // it staying active so the app remains alive for the next alarm.
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // .playback => audible even when the ringer/silent switch is off.
        // .duckOthers is intentionally NOT used: we want to dominate.
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private static func url(for soundName: String) -> URL? {
        Bundle.main.url(forResource: soundName, withExtension: "caf")
            ?? Bundle.main.url(forResource: soundName, withExtension: "wav")
    }
}
