// Shared contracts between the core, the window layer, the calendar service and call detection.
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

    /// The switch is on but the calendar cannot be read: access was refused, or the grant was
    /// lost (a re-signed build, a reset in System Settings). Breaks are not held meanwhile;
    /// the views show a warning that stays until the user re-enables access or turns the
    /// switch off.
    var needsAccess: Bool { enabled && access != .granted }
}

/// What the scheduler asks before firing a break.
@MainActor
protocol BusySource: AnyObject {
    /// When a break due at `now` should fire instead (end of the current busy block plus the
    /// grace period), or `nil` to fire now: feature off, no access, free, or a stale cache.
    /// A source that cannot know when it stops being busy (a camera or microphone in use)
    /// returns a date a short while ahead; the scheduler asks again then, so the hold lasts as long as it keeps
    /// answering.
    func heldUntil(now: Date) -> Date?
    /// Re-read the underlying state (calendar store, cameras and microphones) so a change a
    /// moment ago still counts.
    func refresh() async
}

/// Several sources as one: the break waits for the one that holds it longest.
@MainActor
final class BusySources: BusySource {
    private let sources: [BusySource]

    init(_ sources: [BusySource]) {
        self.sources = sources
    }

    func heldUntil(now: Date) -> Date? {
        sources.compactMap { $0.heldUntil(now: now) }.max()
    }

    func refresh() async {
        for source in sources {
            await source.refresh()
        }
    }
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
    /// Start the periodic refresh (every minute). Never asks for access: macOS is asked only
    /// from `requestAccess()`, which the model calls when the user ticks the switch or picks
    /// "re-enable" in the warning.
    func start()
    /// Ask macOS for calendar access if never asked; resolves once the user answers. Only
    /// ever called in answer to a click.
    func requestAccess() async -> CalendarAccess
    /// System Settings → Privacy & Security → Calendars.
    func openPrivacySettings()
}

// MARK: - Calls (camera or microphone in use)

/// What gives a call away without a calendar.
enum CallDevice: String, CaseIterable, Sendable {
    case camera
    case microphone
}

struct CallStatus: Equatable, Sendable {
    var enabled: Bool
    /// The kinds of device some app is using right now. Always empty while the feature is off.
    var active: Set<CallDevice>

    var inUse: Bool { !active.isEmpty }

    static let off = CallStatus(enabled: false, active: [])
}

/// Call detection (`CallDetector`): a second, calendar-independent sign of a call. While any
/// app uses a camera or a microphone a due break is held, and for the grace period after the
/// last one goes off. It reads only whether a device is in use: it cannot see, hear or record
/// anything, and needs no permission. Owned and configured by `AppModel`.
@MainActor
protocol CallDetecting: BusySource {
    /// Mirrors `Settings.calls.enabled`; set by the model whenever settings change. Devices
    /// are watched only while this is true.
    var enabled: Bool { get set }
    /// Mirrors `Settings.calendar.graceSecs` (one pause after a call for both signals).
    var graceSecs: Int { get set }
    var status: CallStatus { get }
    /// Fired whenever `status` changes.
    var onStatusChanged: ((CallStatus) -> Void)? { get set }
    /// Start watching (when enabled). Call once at startup.
    func start()
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
    /// After a cover's exit button ended the break: if the same covers are still up a moment
    /// later, the app stops (`EscapeRules`).
    func ensureBreakCoversClosed()
    /// The menu popover under the status item, on the given pane.
    func openMenu(pane: MenuPane)
    func closeMenu()
}
