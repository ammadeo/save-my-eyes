// The menu's settings pane: breaks, meetings (the calendar and camera/microphone switches apply at once),
// sounds and language, then Revert / Save with a notice, and the credits. Port of
// MenuSettings.vue + MenuCalendar.vue.

import SwiftUI

private enum T {
    static let meetings = L("Meetings", "Spotkania")
    static let toggle = L("Pause breaks during calendar events", "Bez przerw w trakcie spotkań")
    static let calls = L("Pause breaks while camera or microphone is on", "Bez przerw w trakcie rozmów")
    static let callsDetail = L(
        "Save My Eyes only knows that an app is using them: it can't see, hear or record anything.",
        "Za rozmowę uznajemy użycie kamery lub mikrofonu przez dowolną aplikację. Save My Eyes wie tylko, że są włączone: nie może niczego zobaczyć, usłyszeć ani nagrać.")
    static let grace = L("Resume breaks after a meeting ends", "Wstrzymaj przerwy po zakończeniu rozmowy")
    static let graceZero = L("Immediately", "Od razu")
    static let hint = L(
        "Uses events from the Calendar app. All-day, declined and free events don't count. For Google Calendar, add your Google account in System Settings › Internet Accounts.",
        "Przerwa wypadająca w trakcie wydarzenia z aplikacji Kalendarz poczeka do jego końca. Aby użyć Kalendarza Google, dodaj konto Google w Ustawieniach systemowych › Konta internetowe.")
}

struct MenuSettingsPane: View {
    let model: AppModel
    @State private var form: SettingsForm
    @State private var notice: Notice?
    @State private var noticeTask: Task<Void, Never>?

    struct Notice: Equatable {
        enum Kind { case saved, fixed, failed }
        let kind: Kind
        let lines: [String]
    }

    init(model: AppModel) {
        self.model = model
        _form = State(initialValue: SettingsForm(model: model))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle(text: model.t(SettingsStrings.breaks))
                BreakSlidersGroup(model: model, form: form)
            }
            CalendarSection(model: model, grace: $form.draft.calendarGrace)
            SoundsLanguageGroup(model: model, form: form)
            HStack(alignment: .top, spacing: 8) {
                noticeView
                Spacer(minLength: 0)
                SettingsActions(model: model, form: form, onSave: save)
            }
            .frame(minHeight: 24)
            Text(credits)
                .font(.smeFootnote)
                .foregroundStyle(Theme.labelSecondary)
                .tint(Theme.label)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .opensLinks(with: model)
        }
        .onDisappear { noticeTask?.cancel() }
    }

    private var credits: AttributedString {
        linkedText([
            ("\(model.t(SettingsStrings.createdBy)) ", nil),
            (model.t(SettingsStrings.author), SettingsStrings.authorURL),
            (" · \(model.t(SettingsStrings.thanksTo)) ", nil),
            ("Katerina Limpitsouni", SettingsStrings.undrawURL),
            (" \(model.t(SettingsStrings.thanksFor)) · ", nil),
            (model.t(SettingsStrings.coffee), SettingsStrings.coffeeURL),
        ])
    }

    /// Always laid out, only its text changes (a live region inserted with its text is often not read).
    private var noticeView: some View {
        Group {
            if let notice {
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.t(notice.kind == .failed ? SettingsStrings.saveFailed
                                 : notice.kind == .fixed ? SettingsStrings.fixing : SettingsStrings.saved))
                        .fontWeight(.medium)
                    ForEach(notice.lines, id: \.self) { Text($0) }
                }
                .font(.smeFootnote)
                .foregroundStyle(notice.kind == .saved ? Theme.labelSecondary : Theme.warning)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func save() {
        let result = form.save()
        let next = Notice(kind: !result.ok ? .failed : result.messages.isEmpty ? .saved : .fixed, lines: result.messages)
        withAnimation(.easeOut(duration: 0.15)) { notice = next }
        AccessibilityNotification.Announcement(model.t(next.kind == .failed ? SettingsStrings.saveFailed
            : next.kind == .fixed ? SettingsStrings.fixing : SettingsStrings.saved)).post()
        noticeTask?.cancel()
        let delay = 2.5 + Double(result.messages.count) * 3
        noticeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.15)) { notice = nil }
        }
    }
}

/// Meetings: the calendar switch (small print saying which events count, and the access
/// warning under it when the switch is on but the calendar cannot be read), the camera or
/// microphone switch (small print saying what the app can and cannot know), then the pause
/// after a meeting, which applies to both. The switches apply at once (ticking the calendar one is what shows the macOS
/// permission prompt; the calls one needs no permission), the grace slider goes with the draft.
private struct CalendarSection: View {
    let model: AppModel
    @Binding var grace: Int
    @State private var busy = false
    @State private var pending: Bool?

    private var enabled: Bool { pending ?? model.settings.calendar.enabled }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: model.t(T.meetings))
            GlassGroup {
                SwitchRow(label: model.t(T.toggle), detail: model.t(T.hint),
                          isOn: Binding(get: { enabled }, set: { apply($0) }),
                          disabled: busy)
                if enabled && model.calendarStatus.needsAccess {
                    GroupDivider()
                    CalendarAccessWarning(model: model, disabled: busy)
                }
                GroupDivider()
                SwitchRow(label: model.t(T.calls), detail: model.t(T.callsDetail),
                          isOn: Binding(get: { model.settings.calls.enabled },
                                        set: { _ = model.setCallsEnabled($0) }))
                GroupDivider()
                SliderRow(label: model.t(T.grace), value: $grace, range: SettingsFormRules.calendarGraceMin,
                          scale: 60, suffix: model.t(Strings.minutesSuffix), zeroLabel: model.t(T.graceZero))
            }
        }
        // Reads access only (never prompts), so a grant given in System Settings shows here.
        .task { await model.refreshCalendar() }
    }

    private func apply(_ on: Bool) {
        busy = true
        pending = on
        Task { @MainActor in
            await model.setCalendarEnabled(on)
            pending = nil
            busy = false
        }
    }
}
