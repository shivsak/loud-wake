import SwiftUI

struct AlarmEditView: View {
    @State private var draft: Alarm
    @State private var previewing = false
    @Environment(\.dismiss) private var dismiss
    private let onSave: (Alarm) -> Void

    init(alarm: Alarm, onSave: @escaping (Alarm) -> Void) {
        _draft = State(initialValue: alarm)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        timePicker
                        labelField
                        repeatDays
                        challengeSection
                        soundSection
                        previewButton
                    }
                    .padding(Theme.gutter)
                    .padding(.bottom, 40)
                }
            }
            .fullScreenCover(isPresented: $previewing) {
                ChallengePreviewView(alarm: previewAlarm)
            }
            .navigationTitle(draft.label.isEmpty ? "Alarm" : draft.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if draft.challenge.kinds.isEmpty { draft.challenge.kinds = [.math] }
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }

    // MARK: Sections

    /// The draft with at least one challenge, used for previewing.
    private var previewAlarm: Alarm {
        var a = draft
        if a.challenge.kinds.isEmpty { a.challenge.kinds = [.math] }
        return a
    }

    private var previewButton: some View {
        Button {
            Haptics.tap()
            previewing = true
        } label: {
            Label("Preview alarm", systemImage: "play.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, 4)
    }

    private var timePicker: some View {
        DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .card()
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = draft.hour; c.minute = draft.minute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                draft.hour = c.hour ?? draft.hour
                draft.minute = c.minute ?? draft.minute
            }
        )
    }

    private var labelField: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Label")
            TextField("Wake up", text: $draft.label)
                .font(Theme.displayFont(18, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
        }
    }

    private var repeatDays: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Repeat")
            HStack(spacing: 8) {
                ForEach(Weekday.displayOrder) { day in
                    let on = draft.repeatDays.contains(day)
                    Button {
                        Haptics.tap()
                        if on { draft.repeatDays.remove(day) } else { draft.repeatDays.insert(day) }
                    } label: {
                        Text(day.shortLabel)
                            .font(Theme.displayFont(16, weight: .semibold))
                            .foregroundStyle(on ? Color.black : Theme.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(on ? Theme.accent : Theme.surfaceRaised, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Wake-up challenge")

            VStack(spacing: 10) {
                ForEach(ChallengeKind.allCases) { kind in
                    challengeToggle(kind)
                }
            }

            HStack {
                Text("Difficulty").font(Theme.displayFont(15, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: $draft.challenge.difficulty) {
                    ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }

            Stepper(value: $draft.challenge.repsPerKind, in: 1...10) {
                HStack {
                    Text("Rounds each").font(Theme.displayFont(15, weight: .medium)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("\(draft.challenge.repsPerKind)").font(Theme.displayFont(17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .card()
    }

    private func challengeToggle(_ kind: ChallengeKind) -> some View {
        let on = draft.challenge.kinds.contains(kind)
        return Button {
            Haptics.tap()
            if on {
                draft.challenge.kinds.removeAll { $0 == kind }
            } else {
                draft.challenge.kinds.append(kind)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(on ? Theme.accent : Theme.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(Theme.displayFont(16, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text(kind.subtitle).font(Theme.displayFont(13, weight: .regular)).foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(on ? Theme.accent : Theme.textTertiary)
            }
            .padding(14)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Sound")
            HStack {
                Image(systemName: "speaker.wave.3.fill").foregroundStyle(Theme.accent)
                Picker("", selection: $draft.soundName) {
                    ForEach(AlarmSound.all, id: \.name) { Text($0.title).tag($0.name) }
                }
                .pickerStyle(.menu)
                .tint(Theme.textPrimary)
                Spacer()
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.displayFont(12, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
            .tracking(0.8)
    }
}
