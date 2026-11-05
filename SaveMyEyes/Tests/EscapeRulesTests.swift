import XCTest
@testable import SaveMyEyes

/// The break's escape hatch: when a cover's exit button counts as reachable, and how the
/// watchdog decides the app must crash.
final class EscapeRulesTests: XCTestCase {
    private let screen = CGSize(width: 1440, height: 900)

    func testButtonInsideTheCoverIsReachable() {
        let frame = CGRect(x: 1100, y: 300, width: 220, height: 40)
        XCTAssertTrue(EscapeRules.skipButtonReachable(frame: frame, in: screen))
        // Flush with the edges (and a rounding point past them) still counts.
        XCTAssertTrue(EscapeRules.skipButtonReachable(frame: CGRect(x: -0.5, y: 0, width: 1440.5, height: 900), in: screen))
    }

    func testMissingEmptyOrOffscreenButtonIsUnreachable() {
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: nil, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .zero, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .null, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .infinite, in: screen))
        // Laid out past the bottom or right edge (content taller or wider than the display).
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 1100, y: 880, width: 220, height: 40), in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 1300, y: 300, width: 220, height: 40), in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: -300, y: 300, width: 220, height: 40), in: screen))
        // A cover with no size yet.
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 0, y: 0, width: 220, height: 40), in: .zero))
    }

    // MARK: Watchdog

    func testAnsweredPingsNeverStall() {
        var counter = WatchdogCounter(limit: 3)
        for n in 1...100 {
            XCTAssertEqual(counter.tick(), .ping(n))
            counter.pong(n, exitReachable: true)
        }
    }

    func testStallAfterLimitTicksWithoutAnswer() {
        var counter = WatchdogCounter(limit: 3)
        XCTAssertEqual(counter.tick(), .ping(1))
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testLateAnswerResetsTheCount() {
        var counter = WatchdogCounter(limit: 3)
        XCTAssertEqual(counter.tick(), .ping(1))
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .wait)
        // The main thread catches up just in time (a slow moment, or waking from sleep).
        counter.pong(1, exitReachable: true)
        XCTAssertEqual(counter.tick(), .ping(2))
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testStaleAnswerDoesNotCountForANewerPing() {
        var counter = WatchdogCounter(limit: 2)
        XCTAssertEqual(counter.tick(), .ping(1))
        counter.pong(1, exitReachable: true)
        XCTAssertEqual(counter.tick(), .ping(2))
        counter.pong(1, exitReachable: true)
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testLimitIsAtLeastOneTick() {
        var counter = WatchdogCounter(limit: 0)
        XCTAssertEqual(counter.limit, 1)
        XCTAssertEqual(counter.tick(), .ping(1))
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testDefaultLimitsAreTheEscapeRules() {
        XCTAssertEqual(WatchdogCounter().limit, EscapeRules.watchdogLimit)
        XCTAssertEqual(WatchdogCounter().exitMissingLimit, EscapeRules.exitMissingLimit)
    }

    // MARK: No reachable exit

    private func answer(_ counter: inout WatchdogCounter, exitReachable: Bool) -> WatchdogCounter.Step {
        let step = counter.tick()
        if case .ping(let n) = step { counter.pong(n, exitReachable: exitReachable) }
        return step
    }

    func testTrappedAfterTheLimitWithoutAnExit() {
        var counter = WatchdogCounter(limit: 20, exitMissingLimit: 3)
        for n in 1...3 {
            XCTAssertEqual(answer(&counter, exitReachable: false), .ping(n))
        }
        XCTAssertEqual(counter.tick(), .trapped)
    }

    func testReachableExitResetsTheCount() {
        var counter = WatchdogCounter(limit: 20, exitMissingLimit: 3)
        for _ in 1...10 {
            _ = answer(&counter, exitReachable: false)
            _ = answer(&counter, exitReachable: false)
            _ = answer(&counter, exitReachable: true)
        }
        XCTAssertEqual(counter.unreachable, 0)
        XCTAssertNotEqual(counter.tick(), .trapped)
    }

    func testAGapInAnswersDoesNotCountAsMissingExit() {
        // System sleep: no ticks and no answers, so nothing adds up.
        var counter = WatchdogCounter(limit: 20, exitMissingLimit: 3)
        _ = answer(&counter, exitReachable: false)
        XCTAssertEqual(counter.tick(), .ping(2))
        XCTAssertEqual(counter.unreachable, 1)
    }

    func testStaleAnswerDoesNotCountTowardsTrapped() {
        var counter = WatchdogCounter(limit: 20, exitMissingLimit: 2)
        XCTAssertEqual(counter.tick(), .ping(1))
        counter.pong(1, exitReachable: false)
        counter.pong(1, exitReachable: false)
        XCTAssertEqual(counter.unreachable, 1)
    }

    func testExitLimitIsLongEnoughToNeverCrashOnASlowRender() {
        XCTAssertGreaterThanOrEqual(EscapeRules.exitMissingLimit, 5)
        XCTAssertLessThan(EscapeRules.exitMissingLimit, EscapeRules.watchdogLimit)
    }
}
