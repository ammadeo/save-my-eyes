// Break state machine and timer: idle --(timer)--> before --(start)--> active --(end)--> idle.
//
// A break that comes due during a call (a calendar meeting, or a camera or microphone in
// use) is held until the call ends (`BusySource.heldUntil`, asked again each time the hold
// runs out); if a long break would have come due while it waited, the held break becomes
// that long break (`indexAfterHold`). Everything runs on the main actor; the window layer is
// driven through the `onFire` / `onCloseBreakWindows` callbacks.

import Foundation

// MARK: - Pure rules (unit tested)

enum BreakRules {
    /// `breakIndex` after `setNextBreak`: forced long jumps to the long slot, forced short to 1.
    static func nextBreakIndex(old: Int, force: ForceType?, longEvery: Int) -> Int {
        switch force {
        case .long: longEvery
        case .short: 1
        case nil: old == Int.max ? old : old + 1
        }
    }

    static func isLong(breakIndex: Int, longEvery: Int) -> Bool {
        breakIndex % max(longEvery, 1) == 0
    }

    /// The index a break held since `since` (when it was due as break `index`) has when it
    /// fires at `firesAt`: the first long break among the slots that would have come due
    /// every `every` seconds meanwhile, so a long meeting is followed by a long break and not
    /// by the short one it swallowed first. Nothing changes when no long slot passed.
    static func indexAfterHold(index: Int, since: Date, firesAt: Date, every: Int, longEvery: Int) -> Int {
        let waited = max(0, Int(firesAt.timeIntervalSince(since).rounded(.down)))
        // One full cycle always holds a long break; no need to look further.
        let missed = min(waited / max(every, 1), max(longEvery, 1))
        for i in index...(index > Int.max - missed ? Int.max : index + missed) where isLong(breakIndex: i, longEvery: longEvery) {
            return i
        }
        return index
    }

    static func breakLength(isLong: Bool, breaks: Settings.Breaks) -> Int {
        isLong ? breaks.long.last : breaks.short.last
    }

    /// Seconds until the next break fires. A dev override replaces any non-zero delay
    /// (`SME_DEV_EVERY_SECS`); zero always means "now".
    static func effectiveDelay(inSecs: Int?, every: Int, devOverride: Int?) -> Int {
        let d = inSecs ?? every
        if d == 0 { return 0 }
        return devOverride ?? d
    }

    /// `SME_DEV_EVERY_SECS` (dev aid): replaces every non-zero break delay with this many seconds.
    static var devOverride: Int? {
        ProcessInfo.processInfo.environment["SME_DEV_EVERY_SECS"].flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

// MARK: - Runtime

@MainActor
final class Scheduler {
    enum Fired: Equatable {
        /// Show the before-break card.
        case before
        /// Go straight to the break (skipBeforeBreak or the user started it).
        case breakNow
    }

    /// How often the wall-clock deadline is re-checked (timers do not run during sleep).
    static let watchdogInterval: TimeInterval = 30

    var settings: () -> Settings
    var busySource: BusySource?
    var onStateChanged: ((BreakState) -> Void)?
    var onFire: ((Fired) -> Void)?
    var onCloseBreakWindows: (() -> Void)?

    private(set) var breakIndex = 0
    private(set) var phase: Phase = .idle
    private(set) var scheduledAt: Date?
    private(set) var startedAt: Date?
    /// Frozen at `startBreak` so a settings change does not alter a running break.
    private(set) var activeLength = 0
    private var skipBeforeBreak = false
    private(set) var heldForMeeting = false
    private var held: Hold?
    /// Bumped on every (re)schedule and on break start; a timer only fires if it still matches.
    private(set) var generation: UInt64 = 0
    private var timer: Timer?
    private var watchdog: Timer?

    private struct Hold {
        let index: Int
        /// When the break was originally due.
        let since: Date
    }

    init(settings: @escaping () -> Settings) {
        self.settings = settings
    }

    var snapshot: BreakState {
        let s = settings()
        let long = BreakRules.isLong(breakIndex: breakIndex, longEvery: s.breaks.long.every)
        return BreakState(
            breakIndex: breakIndex,
            isLong: long,
            phase: phase,
            scheduledAt: scheduledAt,
            lengthSecs: phase == .active ? activeLength : BreakRules.breakLength(isLong: long, breaks: s.breaks),
            startedAt: startedAt,
            heldForMeeting: heldForMeeting
        )
    }

    /// Start the sleep/wake watchdog. Call once at startup.
    func start() {
        watchdog?.invalidate()
        let t = Timer(timeInterval: Scheduler.watchdogInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.checkDeadline() }
        }
        t.tolerance = 5
        RunLoop.main.add(t, forMode: .common)
        watchdog = t
    }

    // MARK: Commands

    /// Schedule the next break. Closes break windows unless `keepWindows`; `inSecs == 0`
    /// fires at once (a meeting does not hold a break the user asked for).
    @discardableResult
    func setNextBreak(_ opts: NextBreakOptions = NextBreakOptions()) -> BreakState {
        let s = settings()
        let delay = BreakRules.effectiveDelay(inSecs: opts.inSecs, every: s.breaks.every, devOverride: BreakRules.devOverride)
        breakIndex = BreakRules.nextBreakIndex(old: breakIndex, force: opts.forceType, longEvery: s.breaks.long.every)
        phase = .idle
        startedAt = nil
        skipBeforeBreak = opts.skipBeforeBreak
        heldForMeeting = false
        held = nil
        let generation = arm(at: Date().addingTimeInterval(TimeInterval(delay)))
        let state = snapshot
        // State is already idle, so the window close hooks see no user skip.
        if !opts.keepWindows {
            onCloseBreakWindows?()
        }
        emit(state)
        if delay == 0 {
            return fire(generation: generation, hold: false) ?? state
        }
        return state
    }

    /// The user starts the break (from the before-break card or `skipBeforeBreak`).
    @discardableResult
    func startBreak() -> BreakState {
        beginActive()
        let state = snapshot
        onFire?(.breakNow)
        emit(state)
        return state
    }

    /// The break is over: schedule the next one.
    @discardableResult
    func endBreak() -> BreakState {
        setNextBreak()
    }

    /// Sleep/wake safety: fire if the wall-clock deadline has passed but the timer has not.
    func checkDeadline() async {
        guard phase == .idle, let at = scheduledAt, at <= Date() else { return }
        Log.info("scheduler", "deadline passed without timer (sleep?), firing now")
        let generation = self.generation
        await busySource?.refresh()
        fire(generation: generation, hold: true)
    }

    /// A break window went away. If the app did not close it itself (the phase still says
    /// it should be open), the user dismissed it: closing the before-break card skips this
    /// break, closing the break cover ends it. Both schedule the next one.
    func windowClosed(beforeBreak: Bool) {
        let userClosed = (beforeBreak && phase == .before) || (!beforeBreak && phase == .active)
        if userClosed {
            Log.info("scheduler", "\(beforeBreak ? "before-break" : "break") closed by user in phase \(phase.rawValue)")
            setNextBreak()
        }
    }

    // MARK: Internals

    private func emit(_ state: BreakState) {
        Log.info("scheduler", "phase=\(state.phase.rawValue) index=\(state.breakIndex) long=\(state.isLong) scheduledAt=\(state.scheduledAt.map { ISO8601DateFormatter().string(from: $0) } ?? "nil") length=\(state.lengthSecs)")
        onStateChanged?(state)
    }

    private func cancelTimer() -> UInt64 {
        generation &+= 1
        timer?.invalidate()
        timer = nil
        return generation
    }

    /// Schedule `fire` at `at`; zero or past means the caller fires right away.
    private func arm(at: Date) -> UInt64 {
        let generation = cancelTimer()
        scheduledAt = at
        let delay = at.timeIntervalSinceNow
        if delay > 0 {
            let t = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    // Read the calendar now so a meeting added since the last refresh counts.
                    await self.busySource?.refresh()
                    self.fire(generation: generation, hold: true)
                }
            }
            t.tolerance = min(1, delay / 10)
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
        return generation
    }

    private func beginActive() {
        _ = cancelTimer()
        let s = settings()
        phase = .active
        scheduledAt = nil
        heldForMeeting = false
        startedAt = Date()
        activeLength = BreakRules.breakLength(
            isLong: BreakRules.isLong(breakIndex: breakIndex, longEvery: s.breaks.long.every),
            breaks: s.breaks
        )
    }

    /// Timer expiry: open the before-break card, or go straight to the break when
    /// `skipBeforeBreak`. With `hold`, a break due during a meeting is re-armed for when it
    /// ends instead. No-op when the timer was superseded or the break already fired.
    @discardableResult
    private func fire(generation: UInt64, hold: Bool) -> BreakState? {
        guard generation == self.generation, phase == .idle else { return nil }
        let s = settings()
        let now = Date()
        let every = BreakRules.effectiveDelay(inSecs: nil, every: s.breaks.every, devOverride: BreakRules.devOverride)
        timer = nil
        if hold, let at = busySource?.heldUntil(now: now) {
            let h = held ?? Hold(index: breakIndex, since: scheduledAt ?? now)
            held = h
            breakIndex = BreakRules.indexAfterHold(index: h.index, since: h.since, firesAt: at, every: every, longEvery: s.breaks.long.every)
            let extended = heldForMeeting
            heldForMeeting = true
            _ = arm(at: at)
            let state = snapshot
            if extended {
                // An open-ended hold (a device in use) is asked again every half minute: publish, but
                // do not log each round.
                onStateChanged?(state)
            } else {
                Log.info("scheduler", "in a call, holding break \(state.breakIndex) (long=\(state.isLong))")
                emit(state)
            }
            return state
        }
        if let h = held {
            held = nil
            breakIndex = BreakRules.indexAfterHold(index: h.index, since: h.since, firesAt: now, every: every, longEvery: s.breaks.long.every)
        }
        heldForMeeting = false
        let state: BreakState
        if skipBeforeBreak {
            beginActive()
            state = snapshot
            onFire?(.breakNow)
        } else {
            phase = .before
            state = snapshot
            onFire?(.before)
        }
        emit(state)
        return state
    }
}
