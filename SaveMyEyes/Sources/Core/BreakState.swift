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

    init(inSecs: Int? = nil, forceType: ForceType? = nil, skipBeforeBreak: Bool = false, keepWindows: Bool = false) {
        self.inSecs = inSecs
        self.forceType = forceType
        self.skipBeforeBreak = skipBeforeBreak
        self.keepWindows = keepWindows
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

    /// A break is on screen, or due this instant.
    func isBreakNow(_ now: Date) -> Bool {
        phase != .idle || (scheduledAt.map { $0 <= now } ?? false)
    }
}
