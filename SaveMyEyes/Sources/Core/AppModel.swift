// The one object the views talk to: settings, break state, calendar and call status, and
// every action. Owns the scheduler, the calendar service and call detection; drives the window layer through
// `WindowCoordinating`. Replaces the Tauri commands/events bridge.

import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var settings: Settings
    private(set) var breakState: BreakState
    private(set) var calendarStatus: CalendarStatus
    private(set) var callStatus: CallStatus
    /// Bumped when the break clock reaches zero while the cover stays open (long break or an
    /// open card), so blank covers can switch to "Break has ended".
    private(set) var breakEndedCount = 0
    /// True from the clock reaching zero until the break is over (a cover created late starts
    /// in the finished state).
    private(set) var breakEnded = false

    @ObservationIgnored let scheduler: Scheduler
    @ObservationIgnored let calendar: CalendarServicing
    @ObservationIgnored let calls: CallDetecting
    @ObservationIgnored let sounds = SoundPlayer()
    @ObservationIgnored private let settingsURL: URL
    /// The window layer; set by the app delegate at startup.
    @ObservationIgnored weak var windows: WindowCoordinating?
    /// Fired after a save that changed the language (the status-item menu relabels itself).
    @ObservationIgnored var onLanguageChanged: ((Lang) -> Void)?

    var lang: Lang { settings.lang }

    /// Current-language lookup for the views.
    func t(_ l: L) -> String { settings.lang.pick(l) }

    init(settingsURL: URL = Settings.defaultURL, calendar: CalendarServicing, calls: CallDetecting) {
        self.settingsURL = settingsURL
        let loaded = Settings.load(from: settingsURL)
        Log.info("startup", "settings from \(settingsURL.path): \(loaded)")
        self.settings = loaded
        self.calendar = calendar
        self.calendarStatus = calendar.status
        self.calls = calls
        // Configured before the first read so the published status starts out right.
        calls.enabled = loaded.calls.enabled
        calls.graceSecs = loaded.calendar.graceSecs
        self.callStatus = calls.status
        var scheduler: Scheduler! = nil
        scheduler = Scheduler(settings: { loaded })
        self.scheduler = scheduler
        self.breakState = scheduler.snapshot

        scheduler.settings = { [unowned self] in self.settings }
        scheduler.busySource = BusySources([calendar, calls])
        scheduler.onStateChanged = { [unowned self] state in
            if state.phase != .active { self.breakEnded = false }
            self.breakState = state
        }
        scheduler.onFire = { [unowned self] fired in
            switch fired {
            case .before: self.windows?.openBeforeBreak()
            case .breakNow: self.windows?.openBreakCovers()
            }
        }
        scheduler.onCloseBreakWindows = { [unowned self] in self.windows?.closeBreakWindows() }

        sounds.isEnabled = { [unowned self] in self.settings.sounds.ui }

        calendar.enabled = loaded.calendar.enabled
        calendar.graceSecs = loaded.calendar.graceSecs
        calendar.onStatusChanged = { [unowned self] status in self.calendarStatus = status }
        calls.onStatusChanged = { [unowned self] status in self.callStatus = status }
    }

    /// Start the services and schedule the first break. Returns the initial state (for the
    /// startup notification).
    @discardableResult
    func start() -> BreakState {
        calendar.start()
        calls.start()
        scheduler.start()
        return scheduler.setNextBreak()
    }

    // MARK: Settings

    /// Validate (clamp), persist and publish. Does not reschedule: callers that changed the
    /// cadence call `setNextBreak(NextBreakOptions(keepWindows: true))`.
    @discardableResult
    func saveSettings(_ proposed: Settings) -> (settings: Settings, fixes: [Fix], error: Error?) {
        var next = proposed
        let fixes = next.validate()
        let error = store(next)
        return (next, fixes, error)
    }

    private func store(_ next: Settings) -> Error? {
        let oldLang = settings.lang
        settings = next
        calendar.enabled = next.calendar.enabled
        calendar.graceSecs = next.calendar.graceSecs
        calls.enabled = next.calls.enabled
        calls.graceSecs = next.calendar.graceSecs
        callStatus = calls.status
        var failure: Error?
        do {
            try next.save(to: settingsURL)
        } catch {
            Log.error("settings", "saving \(settingsURL.path): \(error)")
            failure = error
        }
        if oldLang != next.lang {
            onLanguageChanged?(next.lang)
        }
        return failure
    }

    // MARK: Breaks

    @discardableResult
    func setNextBreak(_ opts: NextBreakOptions = NextBreakOptions()) -> BreakState {
        scheduler.setNextBreak(opts)
    }

    @discardableResult
    func startBreak() -> BreakState {
        scheduler.startBreak()
    }

    @discardableResult
    func endBreak() -> BreakState {
        scheduler.endBreak()
    }

    /// The break clock ran out but the cover stays (long break, or an open card).
    func notifyBreakEnded() {
        breakEndedCount += 1
        breakEnded = true
    }

    /// Skip from the before-break card: schedules the next break and closes the card.
    func skipBreak() {
        setNextBreak()
    }

    /// Stop protection: the next break is a long one in `hours`.
    func pauseProtection(hours: Int) {
        setNextBreak(NextBreakOptions(inSecs: hours * 3600, forceType: .long))
    }

    /// "Start a long break now" (menu, tray): straight to the cover, no before-break card.
    func startLongBreakNow() {
        setNextBreak(NextBreakOptions(inSecs: 0, forceType: .long, skipBeforeBreak: true))
    }

    func checkDeadline() {
        Task { await scheduler.checkDeadline() }
    }

    /// Window layer hooks: a before-break card or break cover closed (by the app or the user).
    func beforeBreakWindowClosed() { scheduler.windowClosed(beforeBreak: true) }
    func breakWindowClosed() { scheduler.windowClosed(beforeBreak: false) }

    /// Plays the short/long cue when UI sounds are on; returns when it ended.
    func playBreakSound(long: Bool) async {
        await sounds.play(long: long)
    }

    // MARK: Calendar

    /// Turn meeting-aware breaks on or off. Turning on asks macOS for calendar access the
    /// first time (resolves once the user answers the prompt). Applies at once, not on Save.
    /// This and `restoreCalendarAccess()` are the only places the app asks for access.
    @discardableResult
    func setCalendarEnabled(_ enabled: Bool) async -> CalendarStatus {
        if enabled {
            _ = await calendar.requestAccess()
        }
        var next = settings
        next.calendar.enabled = enabled
        _ = store(next)
        await calendar.refresh()
        calendarStatus = calendar.status
        return calendarStatus
    }

    func openCalendarPrivacy() {
        calendar.openPrivacySettings()
    }

    /// "Re-enable" in the access warning (`CalendarStatus.needsAccess`): ask macOS again when
    /// it can still be asked (the grant was lost), otherwise open Privacy settings, because
    /// macOS shows its prompt only once. "Ignore" is `setCalendarEnabled(false)`.
    func restoreCalendarAccess() async {
        if calendar.status.access == .notDetermined {
            await setCalendarEnabled(true)
        } else {
            openCalendarPrivacy()
        }
    }

    /// Re-read the calendar and its access now (the menu calls this when it opens, so a grant
    /// just given in System Settings clears the warning without waiting for the next minute).
    func refreshCalendar() async {
        await calendar.refresh()
        calendarStatus = calendar.status
    }

    /// Everything the menu's status shows, re-read as it opens: the calendar, and which
    /// devices are in use (a backstop for a listener that did not fire).
    func refreshCallStatus() async {
        await refreshCalendar()
        await calls.refresh()
    }

    // MARK: Calls

    /// Turn "no breaks during calls" (a camera or microphone in use) on or off. Applies at
    /// once, not on Save; no permission is involved.
    @discardableResult
    func setCallsEnabled(_ enabled: Bool) -> CallStatus {
        var next = settings
        next.calls.enabled = enabled
        _ = store(next)
        return callStatus
    }

    // MARK: App

    func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
