// Wire-level break types shared by the scheduler, the model and the views.

import Foundation

enum Phase: String, Equatable, Sendable {
    case idle
    case before
    case active
}

enum ForceType: Equatable, Sendable {
    case long
    case short
}

struct NextBreakOptions: Equatable, Sendable {
    /// Seconds until the break; `nil` means the configured interval, 0 means now.
    var inSecs: Int? = nil
    var forceType: ForceType? = nil
    /// Go straight to the break instead of showing the before-break card first.
    var skipBeforeBreak = false
    /// Leave open break windows alone (a settings save rescheduling mid-break).
    var keepWindows = false
    /// The user stopped protection until this break ("Stop protection for 1–3 hours").
    var stopsProtection = false

    init(inSecs: Int? = nil, forceType: ForceType? = nil, skipBeforeBreak: Bool = false, keepWindows: Bool = false,
         stopsProtection: Bool = false) {
        self.inSecs = inSecs
        self.forceType = forceType
        self.skipBeforeBreak = skipBeforeBreak
        self.keepWindows = keepWindows
        self.stopsProtection = stopsProtection
    }
}

/// Snapshot of the scheduler, published as `AppModel.breakState`.
struct BreakState: Equatable, Sendable {
    var breakIndex: Int
    var isLong: Bool
    var phase: Phase
    /// When the next break fires (idle) or when the before-break phase began (before); nil while active.
    var scheduledAt: Date?
    /// Length of the coming break, frozen while active.
    var lengthSecs: Int
    var startedAt: Date?
    /// The break came due during a meeting and now waits for it to end.
    var heldForMeeting: Bool
    /// The user stopped protection; it comes back with the break at `scheduledAt`.
    var protectionStopped = false

    /// A break is on screen, or due this instant.
    func isBreakNow(_ now: Date) -> Bool {
        phase != .idle || (scheduledAt.map { $0 <= now } ?? false)
    }
}

/// Why breaks are on hold right now. The menu's status and the menu-bar icon both read this,
/// so they cannot disagree.
enum BreakPause: Equatable, Sendable {
    /// The user stopped protection until then.
    case stopped(until: Date)
    /// A calendar event is going on.
    case meeting(Meeting)
    /// A camera or microphone is in use; nobody knows until when.
    case devices(Set<CallDevice>)

    /// `nil` when nothing holds breaks, and while a break is on screen (one the user started
    /// during a meeting is a break, not a pause). Stopped protection comes first: the next
    /// break is hours away whatever the calendar says.
    static func current(state: BreakState, calendar: CalendarStatus, calls: CallStatus, now: Date) -> BreakPause? {
        if state.isBreakNow(now) { return nil }
        if state.protectionStopped, let until = state.scheduledAt { return .stopped(until: until) }
        if let meeting = calendar.meeting, meeting.until > now { return .meeting(meeting) }
        if calls.inUse { return .devices(calls.active) }
        return nil
    }
}
