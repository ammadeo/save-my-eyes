// Shared contracts between the core, the window layer and the calendar service.
// Everything here is main-actor bound; the app is small and single-threaded by design.

import Foundation

// MARK: - Calendar

enum CalendarAccess: String, Equatable, Sendable {
    case notDetermined
    case granted
    case denied
    case restricted
}

/// The meeting going on now and when the busy block it belongs to ends (back-to-back
/// meetings merged, see `CalendarRules`).
struct Meeting: Equatable, Sendable {
    var title: String
    var until: Date
}

struct CalendarStatus: Equatable, Sendable {
    var enabled: Bool
    var access: CalendarAccess
    var meeting: Meeting?
    var syncedAt: Date?

    static let off = CalendarStatus(enabled: false, access: .notDetermined, meeting: nil, syncedAt: nil)
}

/// What the scheduler asks before firing a break.
@MainActor
protocol BusySource: AnyObject {
    /// When a break due at `now` should fire instead (end of the current busy block plus the
    /// grace period), or `nil` to fire now: feature off, no access, free, or a stale cache.
    func heldUntil(now: Date) -> Date?
    /// Re-read the calendar store so a meeting added a moment ago still counts.
    func refresh() async
}

/// EventKit-backed calendar service (`CalendarService`). Owned and configured by `AppModel`.
@MainActor
protocol CalendarServicing: BusySource {
    /// Mirrors `Settings.calendar.enabled`; set by the model whenever settings change.
    var enabled: Bool { get set }
    /// Mirrors `Settings.calendar.graceSecs`.
    var graceSecs: Int { get set }
    var status: CalendarStatus { get }
    /// Fired after every refresh and access change.
    var onStatusChanged: ((CalendarStatus) -> Void)? { get set }
    /// Start the periodic refresh (every minute). Asks for access first when enabled and never asked.
    func start()
    /// Ask macOS for calendar access if never asked; resolves once the user answers.
    func requestAccess() async -> CalendarAccess
    /// System Settings → Privacy & Security → Calendars.
    func openPrivacySettings()
}

// MARK: - Windows

enum MenuPane: String, Sendable {
    case menu
    case settings
    case stopProtection = "stop-protection"
}

/// The window layer (`WindowManager`), driven by the model. Every call is idempotent.
@MainActor
protocol WindowCoordinating: AnyObject {
    /// Notification-style card top-right of the primary display; does not take focus.
    func openBeforeBreak()
    func closeBeforeBreak()
    /// Full-screen break cover on the primary display plus a blank cover on every other
    /// display; closes the before-break card first and focuses the break cover.
    func openBreakCovers()
    /// Before-break card, break cover and blank covers. Never the menu.
    func closeBreakWindows()
    /// The menu popover under the status item, on the given pane.
    func openMenu(pane: MenuPane)
    func closeMenu()
}
