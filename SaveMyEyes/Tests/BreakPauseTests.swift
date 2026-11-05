import XCTest
@testable import SaveMyEyes

/// `BreakPause.current`: what the menu's status and the menu-bar pause icon both go by.
final class BreakPauseTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func state(_ phase: Phase = .idle, dueIn: TimeInterval? = 600, stopped: Bool = false) -> BreakState {
        BreakState(breakIndex: 1, isLong: false, phase: phase, scheduledAt: dueIn.map { now.addingTimeInterval($0) },
                   lengthSecs: 20, startedAt: nil, heldForMeeting: false, protectionStopped: stopped)
    }

    private func calendar(meetingEndsIn: TimeInterval?) -> CalendarStatus {
        CalendarStatus(enabled: true, access: .granted,
                       meeting: meetingEndsIn.map { Meeting(title: "Sync", until: now.addingTimeInterval($0)) }, syncedAt: now)
    }

    private func pause(_ state: BreakState, meetingEndsIn: TimeInterval? = nil, devices: Set<CallDevice> = []) -> BreakPause? {
        BreakPause.current(state: state, calendar: calendar(meetingEndsIn: meetingEndsIn),
                           calls: CallStatus(enabled: true, active: devices), now: now)
    }

    func testNothingHoldsBreaks() {
        XCTAssertNil(pause(state()))
    }

    func testMeetingGoingOn() {
        XCTAssertEqual(pause(state(), meetingEndsIn: 900), .meeting(Meeting(title: "Sync", until: now.addingTimeInterval(900))))
    }

    func testMeetingAlreadyOverInAStaleStatus() {
        XCTAssertNil(pause(state(), meetingEndsIn: -1))
    }

    func testDeviceInUse() {
        XCTAssertEqual(pause(state(), devices: [.microphone]), .devices([.microphone]))
    }

    func testMeetingWinsOverDevices() {
        XCTAssertEqual(pause(state(), meetingEndsIn: 900, devices: [.camera]),
                       .meeting(Meeting(title: "Sync", until: now.addingTimeInterval(900))))
    }

    func testDevicesTakeOverWhenTheMeetingEnds() {
        XCTAssertEqual(pause(state(), meetingEndsIn: -1, devices: [.camera]), .devices([.camera]))
    }

    func testStoppedProtection() {
        XCTAssertEqual(pause(state(dueIn: 7200, stopped: true)), .stopped(until: now.addingTimeInterval(7200)))
    }

    func testStoppedProtectionWinsOverAMeeting() {
        XCTAssertEqual(pause(state(dueIn: 7200, stopped: true), meetingEndsIn: 900, devices: [.camera]),
                       .stopped(until: now.addingTimeInterval(7200)))
    }

    func testABreakOnScreenIsNotAPause() {
        XCTAssertNil(pause(state(.before), meetingEndsIn: 900, devices: [.camera]))
        XCTAssertNil(pause(state(.active, dueIn: nil), meetingEndsIn: 900, devices: [.camera]))
    }

    func testABreakDueThisInstantIsNotAPause() {
        XCTAssertNil(pause(state(dueIn: 0), meetingEndsIn: 900))
    }
}
