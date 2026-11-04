// The menu's settings pane: breaks, meetings (applies at once), sounds and language, then
// Revert / Save with a notice, and the credits. Port of MenuSettings.vue + MenuCalendar.vue.

import SwiftUI

private enum T {
    static let meetings = L("Meetings", "Spotkania")
    static let toggle = L("Don't break during meetings", "Bez przerw w trakcie spotkań")
    static let grace = L("Pause breaks after a call ends", "Wstrzymaj przerwy po zakończeniu rozmowy")
    static let graceZero = L("Immediately", "Od razu")
    static let hint = L(
        "A break that falls during an event from the Calendar app waits until the event ends. For Google Calendar, add your Google account in System Settings › Internet Accounts.",
        "Przerwa wypadająca w trakcie wydarzenia z aplikacji Kalendarz poczeka do jego końca. Aby użyć Kalendarza Google, dodaj konto Google w Ustawieniach systemowych › Konta internetowe.")
    static let denied = L("Save My Eyes has no access to your calendar.", "Save My Eyes nie ma dostępu do kalendarza.")
    static let openSettings = L("Open Privacy Settings…", "Otwórz ustawienia prywatności…")
    static let notAsked = L("Calendar access is needed.", "Potrzebny jest dostęp do kalendarza.")
    static let allow = L("Allow…", "Zezwól…")
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

/// Meetings: the toggle applies at once (it may show the macOS permission prompt), the grace
/// slider goes with the draft.
private struct CalendarSection: View {
    let model: AppModel
    @Binding var grace: Int
    @State private var busy = false
    @State private var pending: Bool?

    private var enabled: Bool { pending ?? model.settings.calendar.enabled }
    private var access: CalendarAccess { model.calendarStatus.access }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: model.t(T.meetings))
            GlassGroup {
                SwitchRow(label: model.t(T.toggle),
                          isOn: Binding(get: { enabled }, set: { apply($0) }),
                          disabled: busy)
                GroupDivider()
                SliderRow(label: model.t(T.grace), value: $grace, range: SettingsFormRules.calendarGraceMin,
                          scale: 60, suffix: model.t(Strings.minutesSuffix), zeroLabel: model.t(T.graceZero))
                if enabled && access == .notDetermined {
                    GroupDivider()
                    GlassRow {
                        Text(model.t(T.notAsked)).frame(maxWidth: .infinity, alignment: .leading)
                        Button(model.t(T.allow)) { apply(true) }
                            .glassButton(.quiet)
                            .disabled(busy)
                    }
                    .foregroundStyle(Theme.labelSecondary)
                }
                if enabled && (access == .denied || access == .restricted) {
                    GroupDivider()
                    GlassRow {
                        Text(model.t(T.denied)).frame(maxWidth: .infinity, alignment: .leading)
                        Button(model.t(T.openSettings)) { model.openCalendarPrivacy() }
                            .glassButton(.quiet)
                    }
                    .foregroundStyle(Theme.labelSecondary)
                }
            }
            Footnote(text: model.t(T.hint))
        }
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
