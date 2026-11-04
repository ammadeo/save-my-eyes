// Port of the unit tests in `src-tauri/src/calendar.rs` (the wire-shape test has no Swift
// counterpart: the status is a struct, not JSON).

import XCTest
@testable import SaveMyEyes

final class CalendarRulesTests: XCTestCase {
    private let grace: TimeInterval = 60

    private func at(_ min: Double) -> Date {
        Date(timeIntervalSince1970: 1_800_000_000 + min * 60)
    }

    private func iv(_ start: Double, _ end: Double) -> Interval {
        Interval(start: at(start), end: at(end))
    }

    private func busy(_ start: Double, _ end: Double, _ title: String) -> Busy {
        Busy(interval: iv(start, end), title: title)
    }

    private func event(_ start: Double, _ end: Double) -> EventInfo {
        EventInfo(interval: iv(start, end), title: "Sync", allDay: false, free: false, canceled: false, declined: false)
    }

    private func until(_ day: [Busy], _ now: Double) -> Date? {
        CalendarRules.currentMeeting(busy: day, now: at(now), grace: grace)?.until
    }

    func testFreeTimeIsNotBusy() {
        XCTAssertNil(until([], 0))
        XCTAssertNil(until([busy(10, 40, "later")], 0))
        XCTAssertNil(until([busy(-40, -10, "over")], 0))
        XCTAssertNil(until([busy(-30, 0, "ends now")], 0))
    }

    func testInsideAMeeting() {
        XCTAssertEqual(
            CalendarRules.currentMeeting(busy: [busy(-10, 20, "Standup")], now: at(0), grace: grace),
            Meeting(title: "Standup", until: at(20))
        )
        XCTAssertEqual(until([busy(0, 30, "starts now")], 0), at(30))
    }

    func testBackToBackMeetingsMerge() throws {
        let day = [busy(30, 60, "c"), busy(-10, 30, "a"), busy(31, 45, "d"), busy(70, 90, "e")]
        let m = try XCTUnwrap(CalendarRules.currentMeeting(busy: day, now: at(0), grace: grace))
        XCTAssertEqual(m.title, "a")
        XCTAssertEqual(m.until, at(60))
    }

    func testTheGraceDecidesWhatCountsAsBackToBack() {
        let day = [busy(-10, 20, "a"), busy(25, 60, "b")]
        // Five minutes apart: one block with a long grace, two blocks with a short one.
        let block = { (grace: TimeInterval) in CalendarRules.currentMeeting(busy: day, now: self.at(0), grace: grace)?.until }
        XCTAssertEqual(block(15 * 60), at(60))
        XCTAssertEqual(block(5 * 60), at(60))
        XCTAssertEqual(block(4 * 60), at(20))
        XCTAssertEqual(block(0), at(20))
        // Zero grace still merges a meeting that starts exactly when the last one ends.
        XCTAssertEqual(
            CalendarRules.currentMeeting(busy: [busy(-10, 20, "a"), busy(20, 40, "b")], now: at(0), grace: 0)?.until,
            at(40)
        )
    }

    func testOverlappingMeetingsTakeTheLatestEnd() throws {
        let m = try XCTUnwrap(CalendarRules.currentMeeting(busy: [busy(-5, 20, "b"), busy(-10, 50, "a")], now: at(0), grace: grace))
        XCTAssertEqual(m.title, "a")
        XCTAssertEqual(m.until, at(50))
    }

    func testARealGapEndsTheBlock() {
        XCTAssertEqual(until([busy(-10, 20, "a"), busy(25, 60, "b")], 0), at(20))
    }

    func testOnlyBusyTimedEventsCount() {
        var allDay = event(-60, 60)
        allDay.allDay = true
        var free = event(-60, 60)
        free.free = true
        var canceled = event(-60, 60)
        canceled.canceled = true
        var declined = event(-60, 60)
        declined.declined = true
        let zero = event(0, 0)
        let found = CalendarRules.busyEvents([allDay, free, canceled, declined, zero, event(-5, 5)])
        XCTAssertEqual(found, [busy(-5, 5, "Sync")])
    }
}
