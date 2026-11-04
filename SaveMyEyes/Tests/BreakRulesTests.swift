import XCTest
@testable import SaveMyEyes

/// Port of the pure-rule tests from the Rust `scheduler.rs`.
final class BreakRulesTests: XCTestCase {
    func testIndexIncrementsByDefault() {
        XCTAssertEqual(BreakRules.nextBreakIndex(old: 0, force: nil, longEvery: 3), 1)
        XCTAssertEqual(BreakRules.nextBreakIndex(old: 5, force: nil, longEvery: 3), 6)
        XCTAssertEqual(BreakRules.nextBreakIndex(old: Int.max, force: nil, longEvery: 3), Int.max)
    }

    func testForcedTypesResetIndex() {
        XCTAssertEqual(BreakRules.nextBreakIndex(old: 7, force: .long, longEvery: 3), 3)
        XCTAssertEqual(BreakRules.nextBreakIndex(old: 7, force: .short, longEvery: 3), 1)
    }

    func testForcedLongIsLongAndShortIsShort() {
        for every in 1...30 {
            XCTAssertTrue(BreakRules.isLong(breakIndex: BreakRules.nextBreakIndex(old: 9, force: .long, longEvery: every), longEvery: every))
        }
        for every in 2...30 {
            XCTAssertFalse(BreakRules.isLong(breakIndex: BreakRules.nextBreakIndex(old: 9, force: .short, longEvery: every), longEvery: every))
        }
        // every == 1: every break is long, including a forced short one (legacy behaviour).
        XCTAssertTrue(BreakRules.isLong(breakIndex: BreakRules.nextBreakIndex(old: 9, force: .short, longEvery: 1), longEvery: 1))
    }

    func testEveryThirdBreakIsLong() {
        XCTAssertEqual((1...6).map { BreakRules.isLong(breakIndex: $0, longEvery: 3) }, [false, false, true, false, false, true])
    }

    func testZeroLongEveryDoesNotCrash() {
        XCTAssertTrue(BreakRules.isLong(breakIndex: 4, longEvery: 0))
    }

    func testHeldBreakBecomesTheLongBreakItSwallowed() {
        let t0 = Date()
        let after = { (mins: Int) in t0.addingTimeInterval(TimeInterval(60 * mins)) }
        let held = { (index: Int, mins: Int) in BreakRules.indexAfterHold(index: index, since: t0, firesAt: after(mins), every: 1200, longEvery: 3) }
        // Short meeting: nothing missed, the short break stays short.
        XCTAssertEqual(held(1, 1), 1)
        XCTAssertEqual(held(1, 19), 1)
        // The next slot was short too.
        XCTAssertEqual(held(1, 20), 1)
        XCTAssertEqual(held(1, 39), 1)
        // The long break's slot passed: fire as that long break.
        XCTAssertEqual(held(1, 40), 3)
        XCTAssertEqual(held(2, 20), 3)
        // Already long: stays long, whatever passed.
        XCTAssertEqual(held(3, 0), 3)
        XCTAssertEqual(held(3, 200), 3)
        // Past one full cycle the first long slot still wins, never a later one.
        XCTAssertEqual(held(4, 300), 6)
        // Clock went backwards: nothing missed.
        XCTAssertEqual(BreakRules.indexAfterHold(index: 1, since: after(5), firesAt: t0, every: 1200, longEvery: 3), 1)
        // Degenerate settings do not crash.
        XCTAssertEqual(BreakRules.indexAfterHold(index: Int.max, since: t0, firesAt: after(100), every: 0, longEvery: 0), Int.max)
    }

    func testLengthFollowsType() {
        let b = Settings.Breaks()
        XCTAssertEqual(BreakRules.breakLength(isLong: true, breaks: b), 300)
        XCTAssertEqual(BreakRules.breakLength(isLong: false, breaks: b), 20)
    }

    func testDelayRules() {
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: nil, every: 1200, devOverride: nil), 1200)
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: 60, every: 1200, devOverride: nil), 60)
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: 0, every: 1200, devOverride: nil), 0)
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: nil, every: 1200, devOverride: 8), 8)
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: 3600, every: 1200, devOverride: 8), 8)
        XCTAssertEqual(BreakRules.effectiveDelay(inSecs: 0, every: 1200, devOverride: 8), 0, "now stays now in dev")
    }
}
