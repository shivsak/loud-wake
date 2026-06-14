import AVFoundation
import Foundation

/// Plays a near-silent tone on infinite loop to keep the app alive in the background, so the
/// in-app fire detector can take over and ring on its own at alarm time (the Alarmy trick).
///
/// Uses `.mixWithOthers` so it doesn't interrupt the user's music/podcasts and stays polite
/// until an alarm actually fires. Costs a little battery — the price of an un-bypassable alarm.
@MainActor
final class KeepAliveAudioController {
    private var player: AVAudioPlayer?

    func start() {
        guard player == nil else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        guard let url = Bundle.main.url(forResource: "keepalive", withExtension: "caf") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            // The file itself is near-silent (~0.0008 amplitude), so keep player volume up:
            // iOS is more likely to keep a backgrounded app alive with real, non-zero output.
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("LoudWake: keep-alive failed: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
