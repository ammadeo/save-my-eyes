import XCTest
@testable import SaveMyEyes

/// Busy source stub: holds until a fixed date when set.
@MainActor
private final class FakeBusy: PauseSource {
    var until: Date?
    var refreshes = 0
    var onPauseChanged: (() -> Void)?
    func pause(now: Date) -> Pause? { until.map { .holding(until: $0) } }
    func refresh() async { refreshes += 1 }
}

/// Runtime behaviour of `Scheduler`: snapshots, transitions, window callbacks, holds.
@MainActor
final class SchedulerTests: XCTestCase {
    private var settings = Settings(lang: .en)
    private var fired: [Scheduler.Fired] = []
    private var closes = 0
    private var states: [BreakState] = []

    private func make() -> Scheduler {
        let s = Scheduler(settings: { [unowned self] in self.settings })
        s.onFire = { [unowned self] in self.fired.append($0) }
        s.onCloseBreakWindows = { [unowned self] in self.closes += 1 }
        s.onStateChanged = { [unowned self] in self.states.append($0) }
        return s
    }

    func testSnapshotShapes() {
        let sch = make()
        var st = sch.snapshot
        XCTAssertEqual(st.breakIndex, 0)
        XCTAssertTrue(st.isLong)
        XCTAssertEqual(st.phase, .idle)
        XCTAssertNil(st.scheduledAt)

        st = sch.setNextBreak(NextBreakOptions(inSecs: 3600))
        XCTAssertEqual(st.breakIndex, 1)
        XCTAssertFalse(st.isLong)
        XCTAssertEqual(st.lengthSecs, 20)
        XCTAssertNotNil(st.scheduledAt)
        XCTAssertEqual(closes, 1)

        _ = sch.setNextBreak(NextBreakOptions(inSecs: 3600, forceType: .long))
        st = sch.startBreak()
        settings.breaks.long.last = 600
        st = sch.snapshot
        XCTAssertEqual(st.phase, .active)
        XCTAssertTrue(st.isLong)
        XCTAssertEqual(st.lengthSecs, 300, "length frozen at start")
        XCTAssertNotNil(st.startedAt)
        XCTAssertNil(st.scheduledAt)
        XCTAssertEqual(fired, [.breakNow])
    }

    func testNowSkipsBeforeBreakWhenAsked() {
        let sch = make()
        let st = sch.setNextBreak(NextBreakOptions(inSecs: 0, forceType: .long, skipBeforeBreak: true))
        XCTAssertEqual(st.phase, .active)
        XCTAssertTrue(st.isLong)
        XCTAssertEqual(st.lengthSecs, 300)
        XCTAssertEqual(fired, [.breakNow])
    }

    func testNowShowsBeforeBreakByDefault() {
        let sch = make()
        let st = sch.setNextBreak(NextBreakOptions(inSecs: 0))
        XCTAssertEqual(st.phase, .before)
        XCTAssertNotNil(st.scheduledAt, "scheduledAt stays set during before")
        XCTAssertEqual(fired, [.before])
        // Starting from the card.
        let active = sch.startBreak()
        XCTAssertEqual(active.phase, .active)
        XCTAssertEqual(fired, [.before, .breakNow])
    }

    func testUserClosingWindowsSkipsOrEnds() {
        let sch = make()
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 0))
        XCTAssertEqual(sch.phase, .before)
        sch.windowClosed(beforeBreak: true) // user skipped
        XCTAssertEqual(sch.phase, .idle)
        XCTAssertEqual(sch.breakIndex, 2)

        _ = sch.setNextBreak(NextBreakOptions(inSecs: 0, skipBeforeBreak: true))
        XCTAssertEqual(sch.phase, .active)
        sch.windowClosed(beforeBreak: true) // a stale card closing: not a user action in this phase
        XCTAssertEqual(sch.phase, .active)
        sch.windowClosed(beforeBreak: false) // user closed the cover
        XCTAssertEqual(sch.phase, .idle)
        XCTAssertEqual(sch.breakIndex, 4)
        // App-initiated: the phase changed first, so the destroy hook is a no-op.
        let before = sch.breakIndex
        sch.windowClosed(beforeBreak: false)
        XCTAssertEqual(sch.breakIndex, before)
    }

    func testKeepWindowsDoesNotClose() {
        let sch = make()
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 3600, keepWindows: true))
        XCTAssertEqual(closes, 0)
    }

    func testTimerFiresAndRefreshesCalendar() async {
        let sch = make()
        let busy = FakeBusy()
        sch.pauseSource = busy
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        XCTAssertEqual(sch.phase, .idle)
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertEqual(sch.phase, .before)
        XCTAssertEqual(busy.refreshes, 1)
        XCTAssertEqual(fired, [.before])
    }

    func testRescheduleSupersedesPendingTimer() async {
        let sch = make()
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 3600))
        try? await Task.sleep(for: .milliseconds(1300))
        XCTAssertEqual(sch.phase, .idle)
        XCTAssertTrue(fired.isEmpty)
    }

    func testMeetingHoldsTheTimerFiredBreak() async {
        let sch = make()
        let busy = FakeBusy()
        busy.until = Date().addingTimeInterval(3600)
        sch.pauseSource = busy
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertEqual(sch.phase, .idle)
        XCTAssertTrue(sch.heldForMeeting)
        XCTAssertEqual(sch.scheduledAt!.timeIntervalSinceNow, 3600, accuracy: 5)
        XCTAssertTrue(fired.isEmpty)
        XCTAssertTrue(states.last!.heldForMeeting)
    }

    func testHeldBreakBecomesLongWhenALongSlotPassed() async {
        let sch = make()
        let busy = FakeBusy()
        // Two full intervals pass during the meeting: break 1 would have been followed by 2 and 3 (long).
        busy.until = Date().addingTimeInterval(TimeInterval(2 * settings.breaks.every + 10))
        sch.pauseSource = busy
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertTrue(sch.heldForMeeting)
        XCTAssertEqual(sch.breakIndex, 3)
        XCTAssertTrue(sch.snapshot.isLong)
    }

    func testUserAskedBreakIsNotHeld() {
        let sch = make()
        let busy = FakeBusy()
        busy.until = Date().addingTimeInterval(3600)
        sch.pauseSource = busy
        let st = sch.setNextBreak(NextBreakOptions(inSecs: 0, forceType: .long, skipBeforeBreak: true))
        XCTAssertEqual(st.phase, .active)
        XCTAssertFalse(st.heldForMeeting)
    }

    func testCheckDeadlineFiresPastDueBreak() async {
        let sch = make()
        let busy = FakeBusy()
        sch.pauseSource = busy
        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        // Simulate sleep: the timer is gone but the deadline passes.
        try? await Task.sleep(for: .milliseconds(200))
        await sch.checkDeadline()
        XCTAssertEqual(sch.phase, .idle, "not due yet")
        try? await Task.sleep(for: .milliseconds(1300))
        // Already fired by the timer; a second check is a no-op in phase before.
        XCTAssertEqual(sch.phase, .before)
        await sch.checkDeadline()
        XCTAssertEqual(fired, [.before])
    }
}
