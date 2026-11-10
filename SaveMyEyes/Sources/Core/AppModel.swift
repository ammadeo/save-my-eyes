// The one object the views talk to: settings, break state, calendar and device status, and
// every action. Owns the scheduler, the calendar service and device detection; drives the window layer through
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
    private(set) var deviceStatus: DeviceStatus
    /// Bumped when the break clock reaches zero while the cover stays open (long break or an
    /// open card), so blank covers can switch to "Break has ended".
    private(set) var breakEndedCount = 0
    /// True from the clock reaching zero until the break is over (a cover created late starts
    /// in the finished state).
    private(set) var breakEnded = false

    @ObservationIgnored let scheduler: Scheduler
    @ObservationIgnored let calendar: CalendarServicing
    @ObservationIgnored let devices: DeviceDetecting
    @ObservationIgnored let stopProtection: StopProtection
    /// Everything that can put breaks on hold. A new way to pause breaks is one more
    /// `PauseSource` in this list (see `init`).
    @ObservationIgnored private let pauses: PauseSources
    /// Bumped whenever a source says its answer changed, so views reading `pause(now:)` update.
    private var pauseChanges = 0
    @ObservationIgnored let sounds = SoundPlayer()
    @ObservationIgnored private let settingsURL: URL
    /// The window layer; set by the app delegate at startup.
    @ObservationIgnored weak var windows: WindowCoordinating?
    /// Fired after a save that changed the language (the status-item menu relabels itself).
    @ObservationIgnored var onLanguageChanged: ((Lang) -> Void)?

    var lang: Lang { settings.lang }

    /// The pause in effect at `now`, if breaks are on hold: what the menu-bar icon and the
    /// menu's status show. `nil` while a break is on screen (one the user started during a
    /// meeting is a break, not a pause).
    func pause(now: Date) -> Pause? {
        _ = pauseChanges
        return breakState.isBreakNow(now) ? nil : pauses.pause(now: now)
    }

    /// Current-language lookup for the views.
    func t(_ l: L) -> String { settings.lang.pick(l) }

    init(settingsURL: URL = Settings.defaultURL, calendar: CalendarServicing, devices: DeviceDetecting) {
        self.settingsURL = settingsURL
        let loaded = Settings.load(from: settingsURL)
        Log.info("startup", "settings from \(settingsURL.path): \(loaded)")
        self.settings = loaded
        self.calendar = calendar
        self.calendarStatus = calendar.status
        self.devices = devices
        // Configured before the first read so the published status starts out right.
        devices.enabled = loaded.devices.enabled
        devices.graceSecs = loaded.calendar.graceSecs
        self.deviceStatus = devices.status
        var scheduler: Scheduler! = nil
        scheduler = Scheduler(settings: { loaded })
        self.scheduler = scheduler
        self.breakState = scheduler.snapshot
        let stopProtection = StopProtection()
        self.stopProtection = stopProtection
        // Every way to pause breaks. The scheduler, the menu-bar icon and the menu all go by
        // this one list.
        let pauses = PauseSources([stopProtection, calendar, devices])
        self.pauses = pauses

        scheduler.settings = { [unowned self] in self.settings }
        scheduler.pauseSource = pauses
        pauses.onPauseChanged = { [unowned self] in self.pauseChanges &+= 1 }
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
        devices.onStatusChanged = { [unowned self] status in self.deviceStatus = status }
    }

    /// Start the services and schedule the first break. Returns the initial state (for the
    /// startup notification).
    @discardableResult
    func start() -> BreakState {
        calendar.start()
        devices.start()
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
        devices.enabled = next.devices.enabled
        devices.graceSecs = next.calendar.graceSecs
        deviceStatus = devices.status
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

    /// A cover's exit button (skip or finish): end the break, and make sure the covers really
    /// went away (the app stops if they did not).
    func exitBreak() {
        endBreak()
        windows?.ensureBreakCoversClosed()
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
        stopProtection.stop(until: Date().addingTimeInterval(TimeInterval(hours * 3600)))
        setNextBreak(NextBreakOptions(inSecs: hours * 3600, forceType: .long))
    }

    /// "Start a long break now" (menu, tray): straight to the cover, no before-break card.
    func startLongBreakNow() {
        stopProtection.resume()
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

    /// Re-read the calendar and its access now (the menu devices this when it opens, so a grant
    /// just given in System Settings clears the warning without waiting for the next minute).
    func refreshCalendar() async {
        await calendar.refresh()
        calendarStatus = calendar.status
    }

    /// Everything the menu's status shows, re-read as it opens: the calendar, and which
    /// devices are in use (a backstop for a listener that did not fire).
    func refreshSources() async {
        await refreshCalendar()
        await devices.refresh()
    }

    // MARK: Devices

    /// Turn "pause breaks while camera or microphone is on" on or off. Applies at
    /// once, not on Save; no permission is involved.
    @discardableResult
    func setDevicesEnabled(_ enabled: Bool) -> DeviceStatus {
        var next = settings
        next.devices.enabled = enabled
        _ = store(next)
        return deviceStatus
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
