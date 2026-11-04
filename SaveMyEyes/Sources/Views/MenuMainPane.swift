// The menu's first pane: next-break status (or the meeting going on), the long-break
// shortcut, stop protection / settings rows and Quit. Port of ContentMenu.vue.

import SwiftUI

private enum T {
    static let breakNext = L("Next", "Następna")
    static let breakIn = L("in", "za")
    static let breakIsNow = L("is still going", "trwa")
    static let heldForMeeting = L("Moved to after your meeting", "Przesunięta na czas po spotkaniu")
    static let meetingUntil = L("until {time}", "do {time}")
    static let meetingUntitled = L("Busy", "Zajęte")
    static let callPaused = L("Breaks paused until the end of your call", "Przerwy wstrzymane do końca rozmowy")
    static let callNext = L("Your next break is scheduled after the meeting", "Następna przerwa zaplanowana jest po spotkaniu")
    static let startLongBreak = L("Start a long break now", "Zacznij długą przerwę teraz")
    static let stopProtection = L("Stop protection", "Wstrzymaj ochronę")
    static let settings = L("Settings", "Ustawienia")
    static let quit = L("Quit Save My Eyes", "Zakończ Save My Eyes")
}

struct MenuMainPane: View {
    let model: AppModel
    let open: (MenuPane) -> Void

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                status(now: context.date)
            }

            Button {
                model.startLongBreakNow()
                model.windows?.closeMenu()
            } label: {
                IconLabel(text: model.t(T.startLongBreak), icon: "play.fill", leading: true)
            }
            .glassButton(.primary, size: .large, fullWidth: true)

            GlassGroup {
                GlassRowButton(title: model.t(T.stopProtection), icon: "pause.fill", trailing: .chevron) {
                    open(.stopProtection)
                }
                GroupDivider(inset: 40)
                GlassRowButton(title: model.t(T.settings), icon: "gearshape.fill", trailing: .chevron) {
                    open(.settings)
                }
            }

            GlassGroup {
                GlassRowButton(title: model.t(T.quit), icon: "power", destructive: true, trailing: .shortcut("⌘Q")) {
                    model.quit()
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }

    // MARK: Status

    @ViewBuilder private func status(now: Date) -> some View {
        let state = model.breakState
        let isBreakNow = state.phase != .idle || (state.scheduledAt.map { $0 <= now } ?? false)
        if !isBreakNow, let meeting = model.calendarStatus.meeting, meeting.until > now {
            meetingStatus(meeting)
        } else {
            breakStatus(state: state, isBreakNow: isBreakNow, now: now)
        }
    }

    private func breakStatus(state: BreakState, isBreakNow: Bool, now: Date) -> some View {
        let name = model.t(state.isLong ? Strings.breakLong : Strings.breakShort)
        let label = isBreakNow ? "\(name) \(model.t(T.breakIsNow))" : "\(model.t(T.breakNext)) \(name) \(model.t(T.breakIn))"
        let value = state.scheduledAt.map { HumanDuration.between(now, $0, lang: model.lang) } ?? "—"
        return VStack(alignment: .leading, spacing: 0) {
            Text(label.capitalizedFirst)
                .foregroundStyle(Theme.labelSecondary)
            if !isBreakNow {
                Text(value)
                    .font(.system(size: 26, weight: .medium))
                    .monospacedDigit()
                    .padding(.top, 2)
                if state.heldForMeeting {
                    Text(model.t(T.heldForMeeting))
                        .font(.smeFootnote)
                        .foregroundStyle(Theme.labelSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .statusPadding()
    }

    private func meetingStatus(_ meeting: Meeting) -> some View {
        let title = meeting.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let time = meeting.until.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(model.lang.locale))
        let until = model.t(T.meetingUntil).replacingOccurrences(of: "{time}", with: time)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .accessibilityHidden(true)
                Text(title.isEmpty ? model.t(T.meetingUntitled) : title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("· \(until)")
                    .fixedSize()
            }
            .foregroundStyle(Theme.labelSecondary)
            Text(model.t(T.callPaused))
                .font(.smeTitle2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(model.t(T.callNext))
                .font(.smeFootnote)
                .foregroundStyle(Theme.labelSecondary)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .statusPadding()
    }
}

private extension View {
    /// The status group: 12/14/14 padding inside a glass group.
    func statusPadding() -> some View {
        GlassGroup {
            self
                .padding(.top, 12)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
