import SwiftUI

struct SequenceChallengeView: View {
    let difficulty: Difficulty
    let onPass: () -> Void

    private enum Phase { case memorize, recall }

    @State private var digits: [Int] = []
    @State private var phase: Phase = .memorize
    @State private var revealIndex = -1
    @State private var entry: [Int] = []
    @State private var wrong = false

    private var length: Int { 3 + difficulty.rawValue }   // 4...7

    var body: some View {
        VStack(spacing: 16) {
            ChallengePrompt(
                icon: "square.grid.3x3.fill",
                title: phase == .memorize ? "Memorize the sequence" : "Repeat the sequence"
            )

            Spacer(minLength: 0)

            display

            Spacer(minLength: 0)

            if phase == .recall {
                Numpad(
                    onDigit: { handle(Int($0) ?? 0) },
                    onDelete: { if !entry.isEmpty { entry.removeLast() } }
                )
            } else {
                Text("Watch carefully…")
                    .font(Theme.displayFont(15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxHeight: .infinity)
            }
        }
        .task { await runReveal() }
    }

    private var display: some View {
        HStack(spacing: 8) {
            ForEach(0..<length, id: \.self) { i in
                let revealedDigit = (phase == .memorize && i == revealIndex) ? digits[i] : nil
                let enteredDigit = (phase == .recall && i < entry.count) ? entry[i] : nil
                slot(text: revealedDigit.map(String.init) ?? enteredDigit.map(String.init),
                     filled: enteredDigit != nil || revealedDigit != nil)
            }
        }
        .frame(height: 66)
        .modifier(ShakeEffect(animating: wrong))
    }

    private func slot(text: String?, filled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(filled ? Theme.accent : Theme.stroke, lineWidth: 1.5)
            )
            .overlay(
                Text(text ?? "")
                    .font(Theme.displayFont(28, weight: .bold))
                    .foregroundStyle(Theme.accent)
            )
            .frame(maxWidth: .infinity)
    }

    private func runReveal() async {
        digits = (0..<length).map { _ in Int.random(in: 0...9) }
        phase = .memorize
        revealIndex = -1
        try? await Task.sleep(for: .milliseconds(500))
        for i in 0..<length {
            withAnimation(Theme.snappy) { revealIndex = i }
            Haptics.tap()
            try? await Task.sleep(for: .milliseconds(750))
        }
        withAnimation(Theme.spring) {
            revealIndex = -1
            phase = .recall
        }
    }

    private func handle(_ digit: Int) {
        guard entry.count < length else { return }
        Haptics.tap()
        entry.append(digit)
        if entry.count == length { validate() }
    }

    private func validate() {
        if entry == digits {
            onPass()
        } else {
            Haptics.error()
            withAnimation(Theme.snappy) { wrong.toggle() }
            entry = []
            Task { await runReveal() }   // new sequence, show again
        }
    }
}
