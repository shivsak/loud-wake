import Foundation

/// A day of the week for alarm recurrence. Raw values match Calendar's `weekday` (1 = Sunday).
enum Weekday: Int, Codable, CaseIterable, Identifiable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    /// Single-letter label for compact day pickers (S M T W T F S).
    var shortLabel: String {
        switch self {
        case .sunday: "S"
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "T"
        case .friday: "F"
        case .saturday: "S"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    /// Monday-first ordering for display.
    static let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
}

/// A user-configured alarm.
struct Alarm: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var hour: Int          // 0...23
    var minute: Int        // 0...59
    var label: String
    var repeatDays: Set<Weekday>
    var soundName: String  // base name of a bundled sound file
    var challenge: ChallengeConfig
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        hour: Int = 7,
        minute: Int = 0,
        label: String = "Wake up",
        repeatDays: Set<Weekday> = [],
        soundName: String = AlarmSound.defaultName,
        challenge: ChallengeConfig = .default,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.repeatDays = repeatDays
        self.soundName = soundName
        self.challenge = challenge
        self.isEnabled = isEnabled
    }

    var isRepeating: Bool { !repeatDays.isEmpty }

    /// "7:05 AM" style display string for the user's locale.
    var timeText: String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// True if the alarm should be ringing at `date` (same hour:minute, and weekday matches
    /// for repeating alarms). Used by the in-app fire detector.
    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        guard c.hour == hour, c.minute == minute else { return false }
        guard isRepeating else { return true } // one-off: fire at that minute today
        guard let wd = c.weekday, let day = Weekday(rawValue: wd) else { return false }
        return repeatDays.contains(day)
    }

    /// A key that is unique per minute-occurrence, so an alarm fires only once per minute.
    func occurrenceKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(id.uuidString)-\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)-\(c.hour ?? 0)-\(c.minute ?? 0)"
    }

    var repeatText: String {
        guard isRepeating else { return "Once" }
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let weekend: Set<Weekday> = [.saturday, .sunday]
        if repeatDays == Set(Weekday.allCases) { return "Every day" }
        if repeatDays == weekdays { return "Weekdays" }
        if repeatDays == weekend { return "Weekends" }
        return Weekday.displayOrder
            .filter { repeatDays.contains($0) }
            .map { String($0.fullName.prefix(3)) }
            .joined(separator: " ")
    }
}

/// Bundled alarm sound metadata.
enum AlarmSound {
    static let defaultName = "siren_loud"

    /// File names (without extension) bundled under Resources/Sounds.
    static let all: [(name: String, title: String)] = [
        ("siren_loud", "Siren (loudest)"),
        ("klaxon", "Klaxon"),
        ("rising_beep", "Rising beep"),
    ]

    static func title(for name: String) -> String {
        all.first { $0.name == name }?.title ?? name
    }
}
