import SwiftUI

/// Drives the user through every required challenge round and reports when all are passed.
/// Builds a flat list of rounds (each kind repeated `repsPerKind` times). No back, no skip —
/// the only way forward is to pass each round.
struct ChallengeFlowView: View {
    let config: ChallengeConfig
    let onComplete: () -> Void

    @State private var index = 0

    private var rounds: [ChallengeKind] {
        config.kinds.flatMap { kind in Array(repeating: kind, count: max(1, config.repsPerKind)) }
    }

    var body: some View {
        VStack(spacing: 16) {
            progress

            if index < rounds.count {
                challengeView(for: rounds[index])
                    .id(index) // fresh challenge each round
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(Theme.spring, value: index)
    }

    private var progress: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Challenge \(min(index + 1, rounds.count)) of \(rounds.count)")
                    .font(Theme.displayFont(13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceRaised)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(0, geo.size.width * progressFraction))
                }
            }
            .frame(height: 5)
        }
    }

    private var progressFraction: CGFloat {
        guard !rounds.isEmpty else { return 1 }
        return CGFloat(index) / CGFloat(rounds.count)
    }

    @ViewBuilder
    private func challengeView(for kind: ChallengeKind) -> some View {
        let pass = { advance() }
        switch kind {
        case .math:     MathChallengeView(difficulty: config.difficulty, onPass: pass)
        case .typing:   TypingChallengeView(difficulty: config.difficulty, onPass: pass)
        case .sequence: SequenceChallengeView(difficulty: config.difficulty, onPass: pass)
        case .shake:    ShakeChallengeView(difficulty: config.difficulty, onPass: pass)
        }
    }

    private func advance() {
        Haptics.success()
        if index + 1 >= rounds.count {
            onComplete()
        } else {
            withAnimation(Theme.spring) { index += 1 }
        }
    }
}

/// Compact header used by each challenge subview.
struct ChallengePrompt: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.displayFont(16, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
