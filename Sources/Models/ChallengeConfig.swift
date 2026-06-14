import Foundation

/// The kinds of wake-up challenges the user can require before an alarm goes silent.
enum ChallengeKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case math
    case typing
    case sequence
    case shake

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: "Math"
        case .typing: "Type a phrase"
        case .sequence: "Memory"
        case .shake: "Shake / steps"
        }
    }

    var subtitle: String {
        switch self {
        case .math: "Solve arithmetic problems"
        case .typing: "Type a phrase exactly"
        case .sequence: "Repeat a shown sequence"
        case .shake: "Shake the phone or walk"
        }
    }

    var systemImage: String {
        switch self {
        case .math: "x.squareroot"
        case .typing: "keyboard"
        case .sequence: "square.grid.3x3.fill"
        case .shake: "iphone.gen3.radiowaves.left.and.right"
        }
    }
}

/// How hard the challenges are. Scales problem size and rep counts.
enum Difficulty: Int, Codable, CaseIterable, Identifiable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3
    case brutal = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .brutal: "Brutal"
        }
    }
}

/// Per-alarm challenge configuration: which challenges, how hard, and how many reps.
struct ChallengeConfig: Codable, Hashable, Sendable {
    /// Challenge kinds the user must complete, in the order they appear here.
    var kinds: [ChallengeKind]
    var difficulty: Difficulty
    /// Number of rounds required for each kind before it is considered passed.
    var repsPerKind: Int

    static let `default` = ChallengeConfig(
        kinds: [.math],
        difficulty: .hard,
        repsPerKind: 3
    )

    /// Total rounds across all enabled challenges.
    var totalRounds: Int { kinds.count * max(1, repsPerKind) }
}
