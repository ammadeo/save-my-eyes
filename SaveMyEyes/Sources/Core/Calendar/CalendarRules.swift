// Pure rules for calendar-aware breaks (port of the pure half of `calendar.rs`): which
// events count as busy, and which busy block covers "now". No EventKit here; unit tested in
// `CalendarRulesTests`.

import Foundation

struct Interval: Equatable, Sendable {
    var start: Date
    var end: Date
}

/// One busy calendar event.
struct Busy: Equatable, Sendable {
    var interval: Interval
    var title: String
}

/// What EventKit tells us about one event, reduced to what decides "busy".
struct EventInfo: Equatable, Sendable {
    var interval: Interval
    var title: String
    var allDay: Bool
    /// Availability set to "free" (Google: "Show as available").
    var free: Bool
    var canceled: Bool
    /// The current user is an attendee and declined.
    var declined: Bool
}

enum CalendarRules {
    /// Timed, busy, not canceled and not declined, with a positive length. Everything else
    /// is ignored.
    static func busyEvents(_ events: [EventInfo]) -> [Busy] {
        events
            .filter { !$0.allDay && !$0.free && !$0.canceled && !$0.declined }
            .filter { $0.interval.end > $0.interval.start }
            .map { Busy(interval: $0.interval, title: $0.title) }
    }

    /// The earliest-started meeting covering `now`, with the end of its busy block: meetings
    /// that start within `grace` of the previous one ending are merged (a break that would
    /// fire in that gap would only be held again), overlapping ones take the latest end, and
    /// a real gap ends the block. `nil` when free.
    static func currentMeeting(busy: [Busy], now: Date, grace: TimeInterval) -> Meeting? {
        // Stable sort by start, like Rust's `sort_by_key`, so equal starts keep input order.
        let upcoming = busy.enumerated()
            .filter { $0.element.interval.end > now }
            .sorted { ($0.element.interval.start, $0.offset) < ($1.element.interval.start, $1.offset) }
            .map(\.element)
        var meeting: Meeting?
        for b in upcoming {
            let i = b.interval
            if var m = meeting {
                guard i.start <= m.until.addingTimeInterval(grace) else { break }
                m.until = max(m.until, i.end)
                meeting = m
            } else {
                guard i.start <= now else { break }
                meeting = Meeting(title: b.title, until: i.end)
            }
        }
        return meeting
    }
}

