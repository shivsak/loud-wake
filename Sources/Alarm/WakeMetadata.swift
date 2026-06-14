import AlarmKit
import Foundation

/// Per-alarm metadata carried by AlarmKit so the widget / Live Activity can show context.
struct WakeMetadata: AlarmMetadata {
    var label: String
    var challengeSummary: String

    init(label: String, challengeSummary: String) {
        self.label = label
        self.challengeSummary = challengeSummary
    }
}
