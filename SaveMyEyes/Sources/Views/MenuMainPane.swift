// The menu's first pane: next-break status (or the meeting going on: a calendar event, or a
// camera or microphone in use), the
// calendar access warning when needed, the long-break shortcut, stop protection / settings rows
// and Quit. Port of ContentMenu.vue.

import SwiftUI

private enum T {
    static let breakNext = L("Next", "Następna")
    static let breakIn = L("in", "za")
    static let breakIsNow = L("is still going", "trwa")
    static let heldForMeeting = L("Moved to after your meeting", "Przesunięta na czas po rozmowie")
    static let protectionStopped = L("Protection is stopped until then", "Do tego czasu ochrona jest wstrzymana")
    static let meetingUntil = L("until {time}", "do {time}")
    static let meetingUntitled = L("Busy", "Zajęte")
    static let callPaused = L("Breaks are paused", "Przerwy wstrzymane do końca rozmowy")
    static let callNext = L("Your next break starts after this event ends", "Następna przerwa zaplanowana jest po spotkaniu")
    static let cameraOn = L("Camera is on", "Kamera jest włączona")
    static let microphoneOn = L("Microphone is on", "Mikrofon jest włączony")
    static let cameraAndMicrophoneOn = L("Camera and microphone are on", "Kamera i mikrofon są włączone")
    static let deviceNext = L("Your next break starts once the camera and microphone are off", "Następna przerwa zaplanowana jest po rozmowie")
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

            if model.calendarStatus.needsAccess {
                GlassGroup { CalendarAccessWarning(model: model) }
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
        // The popover builds a fresh pane each time it opens: re-read calendar access (never
        // prompts) so a grant just given in System Settings clears the warning, and which
        // devices are in use.
        .task { await model.refreshCallStatus() }
    }

    // MARK: Status

    @ViewBuilder private func status(now: Date) -> some View {
        switch model.breakPause(now: now) {
        case .meeting(let meeting):
            meetingStatus(meeting)
        case .devices(let active):
            // A camera or microphone in use has no end time; the scheduler keeps re-arming the
            // break a few seconds ahead, so a countdown would only flicker.
            let camera = active.contains(.camera)
            callStatus(icon: camera ? "video" : "mic",
                       label: model.t(active.count > 1 ? T.cameraAndMicrophoneOn : camera ? T.cameraOn : T.microphoneOn),
                       next: model.t(T.deviceNext))
        case .stopped, nil:
            let state = model.breakState
            breakStatus(state: state, isBreakNow: state.isBreakNow(now), now: now)
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
                if state.heldForMeeting || state.protectionStopped {
                    Text(model.t(state.heldForMeeting ? T.heldForMeeting : T.protectionStopped))
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
        return callStatus(icon: "calendar", label: title.isEmpty ? model.t(T.meetingUntitled) : title,
                          until: until, next: model.t(T.callNext))
    }

    /// A meeting is going on (a calendar event, or a camera or microphone in use): what it is, then the pause.
    private func callStatus(icon: String, label: String, until: String? = nil, next: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .accessibilityHidden(true)
                Text(label)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let until {
                    Text("· \(until)")
                        .fixedSize()
                }
            }
            .foregroundStyle(Theme.labelSecondary)
            Text(model.t(T.callPaused))
                .font(.smeTitle2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(next)
                .font(.smeFootnote)
                .foregroundStyle(Theme.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
