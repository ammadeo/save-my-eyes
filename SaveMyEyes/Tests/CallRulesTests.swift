import XCTest
@testable import SaveMyEyes

final class CallRulesTests: XCTestCase {
    private let grace: TimeInterval = 60

    private func at(_ secs: Double) -> Date {
        Date(timeIntervalSince1970: 1_800_000_000 + secs)
    }

    private func held(now: Double, inUse: Bool, offAt: Double?, grace: TimeInterval? = nil) -> Date? {
        CallRules.heldUntil(now: at(now), inUse: inUse, offAt: offAt.map(at), grace: grace ?? self.grace)
    }

    func testInUseHoldsForARecheck() {
        XCTAssertEqual(held(now: 0, inUse: true, offAt: nil), at(CallRules.recheck))
        // In use wins over an older off moment.
        XCTAssertEqual(held(now: 0, inUse: true, offAt: -10), at(CallRules.recheck))
    }

    func testInsideTheGraceHoldsUntilItEnds() {
        XCTAssertEqual(held(now: 0, inUse: false, offAt: 0), at(60))
        XCTAssertEqual(held(now: 59, inUse: false, offAt: 0), at(60))
    }

    func testGraceOverFiresNow() {
        XCTAssertNil(held(now: 60, inUse: false, offAt: 0))
        XCTAssertNil(held(now: 600, inUse: false, offAt: 0))
    }

    func testZeroGraceFiresAsSoonAsTheDeviceIsOff() {
        XCTAssertNil(held(now: 0, inUse: false, offAt: 0, grace: 0))
        XCTAssertEqual(held(now: 0, inUse: true, offAt: nil, grace: 0), at(CallRules.recheck))
    }

    func testNeverOnIsNotHeld() {
        XCTAssertNil(held(now: 0, inUse: false, offAt: nil))
    }
}
