// Shared contracts between the core, the window layer, the calendar service and device detection.
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

// MARK: - Pauses

/// One reason breaks are on hold right now. Everything that pauses breaks (a calendar event,
/// a camera or microphone in use, stopped protection, whatever comes next) is a `PauseSource`
/// answering with one of these, and that one answer does all of it: the scheduler holds a due
/// break until `holdsUntil`, the menu-bar icon shows pause bars, and the menu shows `symbol`,
/// `label`, `endsAt` and `next`. Nothing downstream knows which source it came from, so a
/// new way to pause is a new source in `AppModel`'s list and nothing else.
struct Pause: Equatable, Sendable {
    /// When a break due now fires instead. A source that cannot know when it ends (a device
    /// in use) answers a short while ahead; the scheduler asks again then, so the hold lasts
    /// as long as the source keeps answering.
    var holdsUntil: Date
    /// When the pause ends, if anybody knows; the menu shows it as "until 14:30".
    var endsAt: Date?
    /// SF Symbol for the menu's status line.
    var symbol: String
    /// What is going on: a meeting's title, "Camera is on".
    var label: L
    /// What happens to the next break.
    var next: L
}

private enum T {
    static let afterMeeting = L("Pause after a meeting", "Wstrzymanie po rozmowie")
    static let afterMeetingNext = L("Your next break starts after this pause", "Następna przerwa zacznie się po tym wstrzymaniu")
}

extension Pause {
    /// The pause after a meeting, the same whichever source saw the meeting end (a calendar
    /// event, a camera, a microphone): breaks stay on hold for `grace` after `endedAt`, so a
    /// meeting that runs over or picks up again does not get a break in the gap. `nil` once
    /// it is over.
    static func afterMeeting(endedAt: Date, grace: TimeInterval, now: Date) -> Pause? {
        let until = endedAt.addingTimeInterval(grace)
        guard now < until else { return nil }
        return Pause(holdsUntil: until, endsAt: until, symbol: "hourglass", label: T.afterMeeting, next: T.afterMeetingNext)
    }
}

@MainActor
protocol PauseSource: AnyObject {
    /// The pause in effect at `now`, or `nil` when this source holds nothing: feature off, no
    /// access, free, or a stale cache.
    func pause(now: Date) -> Pause?
    /// Called by the source whenever its answer may have changed for a reason other than time
    /// passing (a pause that ends at `endsAt` needs no call).
    var onPauseChanged: (() -> Void)? { get set }
    /// Re-read the underlying state (calendar store, cameras and microphones) so a change a
    /// moment ago still counts.
    func refresh() async
}

extension PauseSource {
    /// When a break due at `now` should fire instead, or `nil` to fire now.
    func heldUntil(now: Date) -> Date? { pause(now: now)?.holdsUntil }
}

/// Several sources as one: the pause that holds longest is the one in effect.
@MainActor
final class PauseSources: PauseSource {
    private let sources: [PauseSource]
    var onPauseChanged: (() -> Void)?

    init(_ sources: [PauseSource]) {
        self.sources = sources
        for source in sources {
            source.onPauseChanged = { [weak self] in self?.onPauseChanged?() }
        }
    }

    func pause(now: Date) -> Pause? {
        sources.compactMap { $0.pause(now: now) }.max { $0.holdsUntil < $1.holdsUntil }
    }

    func refresh() async {
        for source in sources {
            await source.refresh()
        }
    }
}

/// EventKit-backed calendar service (`CalendarService`). Owned and configured by `AppModel`.
@MainActor
protocol CalendarServicing: PauseSource {
    /// Mirrors `Settings.calendar.enabled`; set by the model whenever settings change.
    var enabled: Bool { get set }
    /// Mirrors `Settings.calendar.graceSecs`.
    var graceSecs: Int { get set }
    var status: CalendarStatus { get }
    /// Fired after every refresh and access change.
    var onStatusChanged: ((CalendarStatus) -> Void)? { get set }
    /// Start the periodic refresh (every minute). Never asks for access: macOS is asked only
    /// from `requestAccess()`, which the model devices when the user ticks the switch or picks
    /// "re-enable" in the warning.
    func start()
    /// Ask macOS for calendar access if never asked; resolves once the user answers. Only
    /// ever called in answer to a click.
    func requestAccess() async -> CalendarAccess
    /// System Settings → Privacy & Security → Calendars.
    func openPrivacySettings()
}

// MARK: - Devices (camera or microphone in use)

/// What gives a meeting away without a calendar.
enum Device: String, CaseIterable, Sendable {
    case camera
    case microphone
}

struct DeviceStatus: Equatable, Sendable {
    var enabled: Bool
    /// The kinds of device some app is using right now. Always empty while the feature is off.
    var active: Set<Device>

    var inUse: Bool { !active.isEmpty }

    static let off = DeviceStatus(enabled: false, active: [])
}

/// Device detection (`DeviceDetector`): a second, calendar-independent sign of a meeting. While any
/// app uses a camera or a microphone a due break is held, and for the grace period after the
/// last one goes off. It reads only whether a device is in use: it cannot see, hear or record
/// anything, and needs no permission. Owned and configured by `AppModel`.
@MainActor
protocol DeviceDetecting: PauseSource {
    /// Mirrors `Settings.devices.enabled`; set by the model whenever settings change. Devices
    /// are watched only while this is true.
    var enabled: Bool { get set }
    /// Mirrors `Settings.calendar.graceSecs` (the one pause after a meeting, whatever told us about it).
    var graceSecs: Int { get set }
    var status: DeviceStatus { get }
    /// Fired whenever `status` changes.
    var onStatusChanged: ((DeviceStatus) -> Void)? { get set }
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
