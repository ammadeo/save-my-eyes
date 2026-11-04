// Calendar-aware breaks: a cached list of busy intervals read from the macOS calendar store
// (EventKit). Google, iCloud and Exchange calendars are in that store once the account is
// added in System Settings → Internet Accounts.
//
// The cache is re-read every minute, when the store changes, and right before a break fires
// (`Scheduler` calls `refresh()`), so a meeting added a moment ago still holds the break. No
// access, a failed read or a stale cache all mean "not busy": a calendar problem never stops
// breaks.

import AppKit
import EventKit
import Foundation

@MainActor
final class CalendarService: CalendarServicing {
    /// Reading the local calendar store is cheap; a minute keeps the menu's meeting line fresh.
    static let refreshEvery: TimeInterval = 60
    /// A cache older than this is ignored (refresh loop stalled, Mac asleep).
    static let staleAfter: TimeInterval = 30 * 60
    static let lookBack: TimeInterval = 12 * 3600
    static let lookAhead: TimeInterval = 12 * 3600

    var enabled = false
    var graceSecs = 60
    var onStatusChanged: ((CalendarStatus) -> Void)?

    private var busy: [Busy] = []
    private var fetchedAt: Date?
    private var store = EKEventStore()
    private var timer: Timer?
    private var storeObserver: NSObjectProtocol?

    private var grace: TimeInterval { TimeInterval(graceSecs) }

    var status: CalendarStatus {
        CalendarStatus(enabled: enabled, access: Self.access(), meeting: meetingNow(Date()), syncedAt: fetchedAt)
    }

    func heldUntil(now: Date) -> Date? {
        guard let meeting = meetingNow(now) else { return nil }
        Log.info("calendar", "in a meeting until \(Self.iso(meeting.until)), holding the break for \(graceSecs)s after")
        return meeting.until.addingTimeInterval(grace)
    }

    /// Re-read busy events into the cache (cleared when disabled or unreadable) and publish
    /// the new status.
    func refresh() async {
        var fetched: [Busy]?
        if enabled {
            switch Self.access() {
            case .granted:
                let now = Date()
                let (from, to) = (now.addingTimeInterval(-Self.lookBack), now.addingTimeInterval(Self.lookAhead))
                let reader = StoreReader(store: store)
                let events = await Task.detached(priority: .utility) { reader.events(from: from, to: to) }.value
                fetched = CalendarRules.busyEvents(events)
            case let access:
                Log.warn("calendar", "no calendar access (\(access.rawValue)), breaks are not held")
            }
        }
        if let fetched {
            Log.info("calendar", "\(fetched.count) busy event(s) around now")
            #if DEBUG
            for b in fetched {
                Log.info("calendar", "busy \(Self.iso(b.interval.start)) – \(Self.iso(b.interval.end)) \"\(b.title)\"")
            }
            #endif
            busy = fetched
            fetchedAt = Date()
        } else {
            busy = []
            fetchedAt = nil
        }
        onStatusChanged?(status)
    }

    /// Refresh every minute and whenever the calendar store changes. When the feature is on
    /// but macOS has never been asked (e.g. a rebuilt, re-signed dev app lost its grant), ask
    /// first.
    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: Self.refreshEvery, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        t.tolerance = 5
        RunLoop.main.add(t, forMode: .common)
        timer = t
        observeStore()
        Task { @MainActor in
            if enabled, Self.access() == .notDetermined {
                _ = await requestAccess()
            }
            await refresh()
        }
    }

    /// Ask macOS for calendar access if it was never asked; resolves once the user answers.
    func requestAccess() async -> CalendarAccess {
        guard Self.access() == .notDetermined else { return Self.access() }
        do {
            let granted = try await store.requestFullAccessToEvents()
            Log.info("calendar", "access request answered: granted=\(granted)")
        } catch {
            Log.warn("calendar", "access request failed: \(error)")
        }
        let access = Self.access()
        if access == .granted {
            // A store created before the grant can keep returning nothing.
            store = EKEventStore()
            observeStore()
        }
        onStatusChanged?(status)
        return access
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Internals

    /// The meeting going on at `now` per a fresh cache, if the feature is on.
    private func meetingNow(_ now: Date) -> Meeting? {
        guard enabled, let at = fetchedAt, now.timeIntervalSince(at) <= Self.staleAfter else { return nil }
        return CalendarRules.currentMeeting(busy: busy, now: now, grace: grace)
    }

    private func observeStore() {
        if let storeObserver { NotificationCenter.default.removeObserver(storeObserver) }
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.enabled else { return }
                await self.refresh()
            }
        }
    }

    private static func access() -> CalendarAccess {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: return .granted
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        // Denied, and write-only access cannot read events.
        default: return .denied
        }
    }

    private static func iso(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}

/// Reads events off the main actor. EKEventStore is not annotated Sendable, but fetching
/// from a background queue is the documented way to use it; the service never mutates the
/// store while a read is in flight (it only replaces its own reference).
private struct StoreReader: @unchecked Sendable {
    let store: EKEventStore

    func events(from: Date, to: Date) -> [EventInfo] {
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: nil)
        return store.events(matching: predicate).compactMap { e in
            guard let start = e.startDate, let end = e.endDate else { return nil }
            let declined = e.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false
            return EventInfo(
                interval: Interval(start: start, end: end),
                title: e.title ?? "",
                allDay: e.isAllDay,
                free: e.availability == .free,
                canceled: e.status == .canceled,
                declined: declined
            )
        }
    }
}
