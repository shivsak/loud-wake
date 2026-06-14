import SwiftUI

@main
struct LoudWakeApp: App {
    @State private var store = AlarmStore()
    @State private var engine = AlarmEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(engine)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .task {
                    store.resync()
                    engine.start(store: store)
                }
                // Present the blocking challenge whenever an alarm is firing.
                .fullScreenCover(item: $engine.firingAlarmID) { id in
                    RingingView(alarmID: id)
                        .environment(store)
                        .environment(engine)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { engine.refresh() }
                }
        }
    }
}

// Allow a UUID to drive `fullScreenCover(item:)`.
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
