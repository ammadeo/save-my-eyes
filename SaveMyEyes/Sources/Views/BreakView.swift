// The full-screen break cover on the primary display. Port of BreakView.vue: title, info,
// countdown, idea card, the exit button, and the stop-protection and settings cards.
//
// Layout (DESIGN.md › Layout): a three-column grid (content | gutter | actions) inside
// clamp(32, 5vw, 64) page padding. Rows: title, info, clock, then the idea card bottom-left
// and the settings button bottom-right. Floating cards are overlays on that grid.

import SwiftUI

private enum T {
    static let finishLong = L("Finish long break", "Zakończ długą przerwę")
    static let finishShort = L("Finish short break", "Zakończ krótką przerwę")
    static let skipLong = L("Skip long break", "Pomiń długą przerwę")
    static let skipShort = L("Skip short break", "Pomiń krótką przerwę")
    static let close = L("Close", "Zamknij")
    static let openSettings = L("Show settings", "Ustawienia")
    static let settingsTitle = L("Settings", "Ustawienia")
}

private enum CoverFocus: Hashable {
    case stopTrigger
    case settingsTrigger
}

struct BreakView: View {
    let model: AppModel

    @State private var isLong: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var finished = false
    @State private var closing = false
    /// The exit button stays disabled until the cover has read the break state.
    @State private var startCloseLock = true

    @State private var stopOpen = false
    @State private var settingsOpen = false
    @State private var settingsForm: SettingsForm
    @State private var fixLog: [String] = []
    @State private var saveFailed = false
    @State private var fixLogHovered = false
    @State private var fixLogTask: Task<Void, Never>?

    @FocusState private var focus: CoverFocus?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel) {
        self.model = model
        let state = model.breakState
        let start = state.startedAt ?? Date()
        _isLong = State(initialValue: state.isLong)
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(TimeInterval(state.lengthSecs)))
        _settingsForm = State(initialValue: SettingsForm(model: model))
    }

    /// An open card pauses the auto-finish of a short break.
    private var autoFinishLock: Bool { stopOpen || settingsOpen }
    /// Unsaved settings block closing the break.
    private var forceCloseLock: Bool { settingsOpen && settingsForm.changed }
    private var hasFixLog: Bool { !fixLog.isEmpty || saveFailed }

    var body: some View {
        GeometryReader { geo in
            content(size: geo.size)
        }
        .foregroundStyle(Theme.label)
        .font(.smeBody)
        .opacity(closing ? 0 : 1)
        .task {
            startCloseLock = false
            await model.playBreakSound(long: isLong)
        }
        .task {
            let wait = endDate.timeIntervalSinceNow
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard !Task.isCancelled else { return }
            await onClockFinished()
        }
        .onDisappear { fixLogTask?.cancel() }
    }

    // MARK: Layout

    private func content(size: CGSize) -> some View {
        let pad = Theme.Space.cover(width: size.width)
        let width = max(0, size.width - 2 * pad)
        let height = max(0, size.height - 2 * pad)
        let right = min(320, max(200, width - 320 - 32))
        let gutter = min(64, max(32, width - 320 - right))
        let left = max(0, width - gutter - right)

        func row<A: View, B: View>(_ alignment: VerticalAlignment, @ViewBuilder _ a: () -> A, @ViewBuilder _ b: () -> B) -> some View {
            HStack(alignment: alignment, spacing: 0) {
                a().frame(width: left, alignment: .leading)
                Color.clear.frame(width: gutter, height: 0)
                b().frame(width: right, alignment: .trailing)
            }
        }

        return VStack(alignment: .leading, spacing: 0) {
            row(.top, { HeaderTitle(model: model) }, { stopTrigger })
            row(.top, {
                TimerInfo(model: model, isLong: isLong, start: startDate, end: endDate, finished: finished)
                    .padding(.top, 64)
                    .padding(.bottom, 16)
            }, { EmptyView() })
            row(.top, {
                CountdownClock(model: model, start: startDate, end: endDate,
                               autoFinish: !isLong && !autoFinishLock, coverWidth: size.width)
            }, { exitButton })
            Spacer(minLength: 24)
            row(.bottom, {
                IdeaCard(model: model, isLong: isLong, finished: finished, forceCloseLock: forceCloseLock,
                         imageHeight: size.width >= 1024 ? 160 : 128)
            }, { settingsTrigger })
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .overlay(alignment: .topTrailing) {
            if stopOpen && !forceCloseLock {
                stopCard
                    .frame(width: right)
                    .frame(maxHeight: height, alignment: .top)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if settingsOpen || hasFixLog {
                settingsCard
                    .frame(width: min(360, width))
                    .frame(maxHeight: height, alignment: .bottom)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(pad)
    }

    // MARK: Exit

    private var exitButton: some View {
        let text = finished ? (isLong ? T.finishLong : T.finishShort) : (isLong ? T.skipLong : T.skipShort)
        return Button { close() } label: {
            IconLabel(text: model.t(text), icon: finished ? "checkmark" : "forward.end.fill")
        }
        .glassButton(finished ? .primary : .quiet, size: .xl)
        .disabled(forceCloseLock || startCloseLock)
    }

    private func close() {
        guard !closing else { return }
        closing = true
        model.endBreak()
    }

    private func onClockFinished() async {
        finished = true
        if !(autoFinishLock || isLong) {
            await model.playBreakSound(long: isLong)
            close()
            return
        }
        model.notifyBreakEnded()
        await model.playBreakSound(long: isLong)
    }

    // MARK: Stop protection

    private var stopTrigger: some View {
        Button { setStop(true) } label: {
            IconLabel(text: model.t(StopStrings.title), icon: "pause.fill")
        }
        .glassButton(.plain)
        .disabled(forceCloseLock)
        .opacity(stopOpen && !forceCloseLock ? 0 : 1)
        .focused($focus, equals: .stopTrigger)
    }

    private var stopCard: some View {
        CloseableCard(title: model.t(StopStrings.title), closeLabel: model.t(T.close), onClose: { setStop(false) }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(model.t(StopStrings.stopFor))
                    .foregroundStyle(Theme.labelSecondary)
                    .padding(.bottom, 8)
                HStack(spacing: 8) {
                    ForEach(StopStrings.hours, id: \.0) { hours, label in
                        Button(model.t(label)) { model.pauseProtection(hours: hours) }
                            .glassButton(.quiet, size: .large, fullWidth: true, hPadding: 6)
                    }
                }
                Text(model.t(StopStrings.turnOffTitle))
                    .foregroundStyle(Theme.labelSecondary)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                Button { model.quit() } label: {
                    IconLabel(text: model.t(StopStrings.turnOffContent), icon: "power")
                }
                .glassButton(.destructive, size: .large, fullWidth: true)
                Text(model.t(StopStrings.turnOffInfo))
                    .font(.smeFootnote)
                    .foregroundStyle(Theme.labelSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
    }

    private func setStop(_ open: Bool) {
        withAnimation(cardAnimation(open)) { stopOpen = open }
        if !open { focus = .stopTrigger }
    }

    // MARK: Settings

    private var settingsTrigger: some View {
        Button { setSettings(true) } label: {
            IconLabel(text: model.t(T.openSettings), icon: "gearshape.fill")
        }
        .glassButton(.quiet, size: .large)
        .opacity(settingsOpen || hasFixLog ? 0 : 1)
        .disabled(settingsOpen || hasFixLog)
        .focused($focus, equals: .settingsTrigger)
    }

    private var settingsCard: some View {
        CloseableCard(title: model.t(T.settingsTitle), closeLabel: model.t(T.close),
                      onClose: { hasFixLog && !settingsOpen ? setSettings(false) : closeSettings() }) {
            if hasFixLog && !settingsOpen {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.t(saveFailed ? SettingsStrings.saveFailed : SettingsStrings.fixing))
                        .foregroundStyle(saveFailed ? Theme.destructive : Theme.warning)
                    ForEach(fixLog, id: \.self) { line in
                        Text(line)
                            .font(.smeFootnote)
                            .foregroundStyle(Theme.labelSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    BreakSlidersGroup(model: model, form: settingsForm)
                    SoundsLanguageGroup(model: model, form: settingsForm)
                    HStack {
                        Spacer()
                        SettingsActions(model: model, form: settingsForm, onSave: closeSettings)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(linkedText([("\(model.t(SettingsStrings.createdBy)) ", nil),
                                         (model.t(SettingsStrings.author), SettingsStrings.authorURL)]))
                        Text(linkedText([("\(model.t(SettingsStrings.thanksTo)) ", nil),
                                         ("Katerina Limpitsouni", SettingsStrings.undrawURL),
                                         (" \(model.t(SettingsStrings.thanksFor))", nil)]))
                    }
                    .font(.smeFootnote)
                    .foregroundStyle(Theme.labelSecondary)
                    .tint(Theme.label)
                    .padding(.horizontal, 12)
                    .opensLinks(with: model)
                }
            }
        }
        .onHover { fixLogHovered = $0 }
    }

    private func setSettings(_ open: Bool) {
        fixLogTask?.cancel()
        withAnimation(cardAnimation(open)) {
            fixLog = []
            saveFailed = false
            settingsOpen = open
        }
        if !open { focus = .settingsTrigger }
    }

    /// Closing saves first when something changed; Save changes closes too. A fix log, if
    /// any, stays in the card for a while.
    private func closeSettings() {
        let result = settingsForm.changed ? settingsForm.save() : nil
        setSettings(false)
        guard let result, !result.messages.isEmpty || !result.ok else { return }
        fixLog = result.messages
        saveFailed = !result.ok
        AccessibilityNotification.Announcement(
            ([model.t(saveFailed ? SettingsStrings.saveFailed : SettingsStrings.fixing)] + fixLog).joined(separator: ". ")
        ).post()
        clearFixLog(after: 2 + Double(max(1, result.messages.count)) * 4)
    }

    private func clearFixLog(after seconds: Double) {
        fixLogTask?.cancel()
        fixLogTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            if fixLogHovered { return clearFixLog(after: 0.5) }
            withAnimation(cardAnimation(false)) {
                fixLog = []
                saveFailed = false
            }
        }
    }

    private func cardAnimation(_ opening: Bool) -> Animation {
        if reduceMotion { return .easeInOut(duration: 0.1) }
        return opening ? .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.32) : .timingCurve(0.4, 0, 1, 1, duration: 0.24)
    }
}
