import CoreMotion
import SwiftUI

/// Counts vigorous phone shakes using the accelerometer.
@MainActor
@Observable
final class ShakeDetector {
    private let manager = CMMotionManager()
    private var lastShake = Date.distantPast

    var count = 0

    func start(threshold: Double = 2.2) {
        guard manager.isAccelerometerAvailable else { return }
        manager.accelerometerUpdateInterval = 1.0 / 30.0
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let a = data?.acceleration else { return }
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            // gravity is ~1g; a real shake spikes well above that
            if magnitude > threshold, Date().timeIntervalSince(self.lastShake) > 0.18 {
                self.lastShake = Date()
                self.count += 1
                Haptics.tap()
            }
        }
    }

    func stop() { manager.stopAccelerometerUpdates() }
}

struct ShakeChallengeView: View {
    let difficulty: Difficulty
    let onPass: () -> Void

    @State private var detector = ShakeDetector()

    private var target: Int { difficulty.rawValue * 10 + 5 } // 15, 25, 35, 45

    private var fraction: Double { min(1, Double(detector.count) / Double(target)) }

    var body: some View {
        VStack(spacing: 36) {
            ChallengePrompt(icon: "iphone.gen3.radiowaves.left.and.right", title: "Shake the phone")

            ZStack {
                Circle()
                    .stroke(Theme.surfaceRaised, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.snappy, value: fraction)
                VStack(spacing: 4) {
                    Text("\(min(detector.count, target))")
                        .font(Theme.displayFont(64, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text("of \(target)")
                        .font(Theme.displayFont(18, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 220, height: 220)

            Text("Shake hard until the ring fills")
                .font(Theme.displayFont(16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
        .onChange(of: detector.count) { _, new in
            if new >= target {
                detector.stop()
                onPass()
            }
        }
    }
}
