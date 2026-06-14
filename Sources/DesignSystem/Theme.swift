import SwiftUI

/// Design tokens for LoudWake. Aesthetic: dark-first, near-monochrome with a single warm
/// accent, large rounded type, generous spacing, soft depth, springy motion.
enum Theme {
    // MARK: Color
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.21)   // warm "wake up" orange
    static let accentSoft = Color(red: 1.0, green: 0.55, blue: 0.30)

    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let surfaceRaised = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let stroke = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.58)
    static let textTertiary = Color.white.opacity(0.32)

    static let success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let danger = Color(red: 1.0, green: 0.30, blue: 0.30)

    // MARK: Spacing
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 16

    // MARK: Type
    static func displayFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: Motion
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.78)
}

// MARK: - Reusable styling

/// A rounded, raised surface used for cards and grouped controls.
struct Card: ViewModifier {
    var padding: CGFloat = Theme.gutter
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = Theme.gutter) -> some View { modifier(Card(padding: padding)) }
}

/// Large primary action button (Apple/OpenAI-style: solid, rounded, confident).
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.displayFont(18, weight: .semibold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.displayFont(17, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Light haptic helpers.
enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

#if canImport(UIKit)
import UIKit
#endif
