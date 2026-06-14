import SwiftUI

struct TypingChallengeView: View {
    let difficulty: Difficulty
    let onPass: () -> Void

    @State private var target = ""
    @State private var entry = ""
    @State private var passed = false
    @FocusState private var focused: Bool

    private var matches: Bool { entry == target }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChallengePrompt(icon: "keyboard", title: "Type this exactly")

            Text(target)
                .font(Theme.displayFont(22, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .card(padding: 16)

            TextField("Start typing…", text: $entry, axis: .vertical)
                .font(Theme.displayFont(19, weight: .medium))
                .foregroundStyle(matches ? Theme.success : Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                        .strokeBorder(matches ? Theme.success : Theme.stroke, lineWidth: 1.5)
                )

            Label(matches ? "Perfect — nicely done" : "Match it exactly, including punctuation",
                  systemImage: matches ? "checkmark.circle.fill" : "info.circle")
                .font(Theme.displayFont(13, weight: .medium))
                .foregroundStyle(matches ? Theme.success : Theme.textTertiary)

            Spacer(minLength: 0)
        }
        .onAppear {
            target = Self.phrases[difficulty]?.randomElement() ?? "I am awake now"
            focused = true
        }
        .onChange(of: entry) { _, _ in
            guard matches, !passed else { return }
            passed = true
            focused = false
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onPass() }
        }
    }

    /// Case-sensitive, punctuation-exact phrases. Harder tiers are longer and trickier.
    static let phrases: [Difficulty: [String]] = [
        .easy: [
            "I am awake now",
            "Time to get up",
            "Rise and shine today",
        ],
        .medium: [
            "Discipline beats motivation every morning",
            "The early hours belong to the focused",
            "I choose progress over comfort today",
        ],
        .hard: [
            "Small consistent actions compound into results.",
            "The quiet morning is where the work happens.",
            "I will not negotiate with my sleepy self.",
        ],
        .brutal: [
            "Success is 1% inspiration, 99% perspiration!",
            "Carpe diem: the obstacle is the way forward.",
            "At 6 AM, champions rise; the rest do not.",
        ],
    ]
}
