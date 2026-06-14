import Foundation

/// Shared identifiers and storage helpers used by both the app and the widget extension.
enum AppGroup {
    static let identifier = "group.com.loudwake.shared"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// Container directory shared between the app and its extensions.
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
