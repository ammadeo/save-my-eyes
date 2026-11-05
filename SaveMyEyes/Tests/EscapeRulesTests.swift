import XCTest
@testable import SaveMyEyes

/// The break's escape hatch: when the native fallback button shows, and the watchdog's
/// stall detection.
final class EscapeRulesTests: XCTestCase {
    private let screen = CGSize(width: 1440, height: 900)

    func testButtonInsideTheCoverIsReachable() {
        let frame = CGRect(x: 1100, y: 300, width: 220, height: 40)
        XCTAssertTrue(EscapeRules.skipButtonReachable(frame: frame, usable: true, in: screen))
        // Flush with the edges (and a rounding point past them) still counts.
        XCTAssertTrue(EscapeRules.skipButtonReachable(frame: CGRect(x: -0.5, y: 0, width: 1440.5, height: 900), usable: true, in: screen))
    }

    func testMissingEmptyOrOffscreenButtonIsUnreachable() {
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: nil, usable: true, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .zero, usable: true, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .null, usable: true, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: .infinite, usable: true, in: screen))
        // Laid out past the bottom or right edge (content taller or wider than the display).
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 1100, y: 880, width: 220, height: 40), usable: true, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 1300, y: 300, width: 220, height: 40), usable: true, in: screen))
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: -300, y: 300, width: 220, height: 40), usable: true, in: screen))
        // A cover with no size yet.
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: CGRect(x: 0, y: 0, width: 220, height: 40), usable: true, in: .zero))
    }

    func testButtonThatIsClosingIsUnreachable() {
        let frame = CGRect(x: 1100, y: 300, width: 220, height: 40)
        XCTAssertFalse(EscapeRules.skipButtonReachable(frame: frame, usable: false, in: screen))
    }

    func testFallbackWaitsForTheGracePeriod() {
        let since = Date(timeIntervalSince1970: 1000)
        XCTAssertFalse(EscapeRules.showsFallback(reachable: false, unreachableSince: since, now: since))
        XCTAssertFalse(EscapeRules.showsFallback(reachable: false, unreachableSince: since,
                                                 now: since.addingTimeInterval(EscapeRules.fallbackAfter - 0.1)))
        XCTAssertTrue(EscapeRules.showsFallback(reachable: false, unreachableSince: since,
                                                now: since.addingTimeInterval(EscapeRules.fallbackAfter)))
        XCTAssertTrue(EscapeRules.showsFallback(reachable: false, unreachableSince: nil, now: since))
    }

    func testFallbackNeverShowsWhileTheButtonIsReachable() {
        let since = Date(timeIntervalSince1970: 1000)
        XCTAssertFalse(EscapeRules.showsFallback(reachable: true, unreachableSince: since, now: since.addingTimeInterval(3600)))
        XCTAssertFalse(EscapeRules.showsFallback(reachable: true, unreachableSince: nil, now: since))
    }

    func testFallbackShowsSoonEnoughToNeverTrap() {
        XCTAssertGreaterThan(EscapeRules.fallbackAfter, 0)
        XCTAssertLessThanOrEqual(EscapeRules.fallbackAfter, 5)
    }

    // MARK: Watchdog

    func testAnsweredPingsNeverStall() {
        var counter = WatchdogCounter(limit: 3)
        for n in 1...100 {
            XCTAssertEqual(counter.tick(), .ping(n))
            counter.pong(n)
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
        counter.pong(1)
        XCTAssertEqual(counter.tick(), .ping(2))
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testStaleAnswerDoesNotCountForANewerPing() {
        var counter = WatchdogCounter(limit: 2)
        XCTAssertEqual(counter.tick(), .ping(1))
        counter.pong(1)
        XCTAssertEqual(counter.tick(), .ping(2))
        counter.pong(1)
        XCTAssertEqual(counter.tick(), .wait)
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testLimitIsAtLeastOneTick() {
        var counter = WatchdogCounter(limit: 0)
        XCTAssertEqual(counter.limit, 1)
        XCTAssertEqual(counter.tick(), .ping(1))
        XCTAssertEqual(counter.tick(), .stalled)
    }

    func testDefaultLimitIsTheWatchdogLimit() {
        XCTAssertEqual(WatchdogCounter().limit, EscapeRules.watchdogLimit)
    }
}
