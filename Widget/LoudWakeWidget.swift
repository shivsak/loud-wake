import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

/// Live Activity presentation for a firing/scheduled LoudWake alarm. Renders on the Lock
/// Screen and in the Dynamic Island. The system draws the alert buttons; this provides the
/// surrounding content and context (the alarm label + challenge summary).
///
/// NOTE: AlarmKit's Live Activity content state type is evolving; if the build flags a
/// mismatch on `context.state`, check Apple's AlarmKit sample (`AlarmPresentationState`).
@main
struct LoudWakeWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoudWakeLiveActivity()
    }
}

struct LoudWakeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<WakeMetadata>.self) { context in
            // Lock Screen / banner
            HStack(spacing: 14) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.metadata?.label ?? "Wake up")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text(context.attributes.metadata?.challengeSummary ?? "Solve to dismiss")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .activityBackgroundTint(.black.opacity(0.85))
            .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.metadata?.label ?? "Wake up")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            } compactLeading: {
                Image(systemName: "alarm.fill").foregroundStyle(.orange)
            } compactTrailing: {
                Image(systemName: "brain.head.profile").foregroundStyle(.orange)
            } minimal: {
                Image(systemName: "alarm.fill").foregroundStyle(.orange)
            }
        }
    }
}
