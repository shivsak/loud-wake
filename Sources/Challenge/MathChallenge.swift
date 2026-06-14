import SwiftUI

/// A generated arithmetic problem with a single integer answer.
struct MathProblem {
    let prompt: String
    let answer: Int

    static func generate(_ difficulty: Difficulty) -> MathProblem {
        switch difficulty {
        case .easy:
            let a = Int.random(in: 11...49), b = Int.random(in: 11...49)
            return MathProblem(prompt: "\(a) + \(b)", answer: a + b)
        case .medium:
            let a = Int.random(in: 21...89), b = Int.random(in: 11...49), c = Int.random(in: 5...29)
            return MathProblem(prompt: "\(a) + \(b) − \(c)", answer: a + b - c)
        case .hard:
            let a = Int.random(in: 12...29), b = Int.random(in: 6...14), c = Int.random(in: 17...88)
            return MathProblem(prompt: "\(a) × \(b) + \(c)", answer: a * b + c)
        case .brutal:
            let a = Int.random(in: 7...19), b = Int.random(in: 6...18)
            let c = Int.random(in: 3...9), d = Int.random(in: 11...59)
            return MathProblem(prompt: "(\(a) + \(b)) × \(c) − \(d)", answer: (a + b) * c - d)
        }
    }
}

struct MathChallengeView: View {
    let difficulty: Difficulty
    let onPass: () -> Void

    @State private var problem: MathProblem = .generate(.hard)
    @State private var entry = ""
    @State private var shake = false

    var body: some View {
        VStack(spacing: 14) {
            ChallengePrompt(icon: "x.squareroot", title: "Solve to continue")

            Spacer(minLength: 0)

            Text(problem.prompt)
                .font(Theme.displayFont(42, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .modifier(ShakeEffect(animating: shake))

            Text(entry.isEmpty ? "—" : entry)
                .font(Theme.displayFont(30, weight: .semibold))
                .foregroundStyle(entry.isEmpty ? Theme.textTertiary : Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .card(padding: 14)

            Spacer(minLength: 0)

            Numpad(
                onDigit: { entry.append($0); Haptics.tap() },
                onDelete: { if !entry.isEmpty { entry.removeLast(); Haptics.tap() } },
                allowNegative: true,
                onToggleSign: toggleSign
            )

            Button("Submit", action: submit)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(entry.isEmpty || entry == "-")
        }
        .onAppear { problem = .generate(difficulty) }
    }

    private func submit() {
        if Int(entry) == problem.answer {
            onPass()
        } else {
            Haptics.error()
            entry = ""
            withAnimation(Theme.snappy) { shake.toggle() }
            problem = .generate(difficulty)   // new problem; no brute-forcing
        }
    }

    private func toggleSign() {
        if entry.hasPrefix("-") { entry.removeFirst() }
        else if !entry.isEmpty { entry = "-" + entry }
    }
}

/// A calculator-style number pad reused by the math and sequence challenges.
struct Numpad: View {
    var onDigit: (String) -> Void
    var onDelete: () -> Void
    var allowNegative = false
    var onToggleSign: () -> Void = {}

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...9, id: \.self) { n in key(text: "\(n)") { onDigit("\(n)") } }
            if allowNegative {
                key(text: "±") { onToggleSign() }
            } else {
                Color.clear.frame(minHeight: 52)
            }
            key(text: "0") { onDigit("0") }
            key(system: "delete.left") { onDelete() }
        }
    }

    private func key(text: String? = nil, system: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let system { Image(systemName: system) } else { Text(text ?? "") }
            }
            .font(Theme.displayFont(24, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Horizontal shake animation for wrong answers.
struct ShakeEffect: GeometryEffect {
    var animating: Bool
    var animatableData: CGFloat = 0

    init(animating: Bool) {
        self.animating = animating
        self.animatableData = animating ? 1 : 0
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let travel = sin(animatableData * .pi * 4) * 9
        return ProjectionTransform(CGAffineTransform(translationX: travel, y: 0))
    }
}
