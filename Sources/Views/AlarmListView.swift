import SwiftUI

struct AlarmListView: View {
    @Environment(AlarmStore.self) private var store
    @State private var editing: Alarm?
    @State private var creatingNew = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if store.alarms.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Alarms")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    creatingNew = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
        .sheet(isPresented: $creatingNew) {
            AlarmEditView(alarm: Alarm()) { store.add($0) }
        }
        .sheet(item: $editing) { alarm in
            AlarmEditView(alarm: alarm) { store.update($0) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.alarms) { alarm in
                    AlarmRow(
                        alarm: alarm,
                        onToggle: { store.setEnabled($0, for: alarm) },
                        onTap: { editing = alarm }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            if let idx = store.alarms.firstIndex(of: alarm) {
                                store.delete(at: IndexSet(integer: idx))
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text("No alarms yet")
                .font(Theme.displayFont(24, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Add an alarm that won't let you\nsleep through it.")
                .font(Theme.displayFont(16, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Add alarm") { creatingNew = true }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 220)
                .padding(.top, 8)
        }
        .padding(40)
    }
}

struct AlarmRow: View {
    let alarm: Alarm
    let onToggle: (Bool) -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(alarm.timeText)
                        .font(Theme.displayFont(40, weight: .semibold))
                        .foregroundStyle(alarm.isEnabled ? Theme.textPrimary : Theme.textTertiary)

                    HStack(spacing: 8) {
                        Text(alarm.label)
                            .foregroundStyle(Theme.textSecondary)
                        Text("•").foregroundStyle(Theme.textTertiary)
                        Text(alarm.repeatText)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .font(Theme.displayFont(14, weight: .medium))
                    .lineLimit(1)

                    Label(AlarmScheduler.challengeSummary(alarm.challenge), systemImage: "lock.fill")
                        .font(Theme.displayFont(12, weight: .medium))
                        .foregroundStyle(Theme.accentSoft)
                        .labelStyle(.titleAndIcon)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { onToggle($0) }))
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}
