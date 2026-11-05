import XCTest
@testable import SaveMyEyes

@MainActor
private final class FakeProbe: CallProbe {
    var running = false
    var onChange: (() -> Void)?
    var observing: Bool { onChange != nil }

    func anyRunning() -> Bool { running }
    func startObserving(_ onChange: @escaping () -> Void) { self.onChange = onChange }
    func stopObserving() { onChange = nil }

    /// Change the camera; `notify: false` simulates a missed listener callback.
    func set(_ running: Bool, notify: Bool = true) {
        self.running = running
        if notify { onChange?() }
    }
}

@MainActor
final class CallDetectorTests: XCTestCase {
    private var probe: FakeProbe!
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)
    private var service: CallDetector!
    private var statuses: [CallStatus] = []

    override func setUp() async throws {
        probe = FakeProbe()
        statuses = []
        service = CallDetector(probes: [.camera: probe], clock: { [unowned self] in self.clock })
        service.graceSecs = 60
        service.onStatusChanged = { [unowned self] in self.statuses.append($0) }
    }

    private func advance(_ secs: TimeInterval) {
        clock = clock.addingTimeInterval(secs)
    }

    private var now: Date { clock }

    func testDisabledWatchesNothingAndNeverHolds() {
        probe.running = true
        service.start()
        XCTAssertFalse(probe.observing)
        XCTAssertEqual(service.status, .off)
        XCTAssertNil(service.heldUntil(now: now))
    }

    func testEnabledBeforeStartWatchesOnStart() {
        service.enabled = true
        XCTAssertFalse(probe.observing)
        probe.running = true
        service.start()
        XCTAssertTrue(probe.observing)
        XCTAssertEqual(service.status, CallStatus(enabled: true, active: [.camera]))
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))
    }

    func testEnablingWhileOffDoesNotHold() {
        service.start()
        service.enabled = true
        XCTAssertTrue(probe.observing)
        XCTAssertEqual(service.status, CallStatus(enabled: true, active: []))
        XCTAssertNil(service.heldUntil(now: now))
    }

    func testOnThenOffHoldsForTheGraceThenFires() {
        service.start()
        service.enabled = true
        probe.set(true)
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))

        advance(100)
        probe.set(false)
        let offAt = now
        XCTAssertEqual(service.status, CallStatus(enabled: true, active: []))
        advance(30)
        XCTAssertEqual(service.heldUntil(now: now), offAt.addingTimeInterval(60))
        advance(30)
        XCTAssertNil(service.heldUntil(now: now))
    }

    func testOnAgainInsideTheGraceHoldsAgain() {
        service.start()
        service.enabled = true
        probe.set(true)
        probe.set(false)
        advance(20)
        probe.set(true)
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))
        // The old off moment is forgotten: going off again starts a fresh grace.
        advance(100)
        probe.set(false)
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(60))
    }

    func testDisablingStopsWatchingAndForgetsTheGrace() {
        service.start()
        service.enabled = true
        probe.set(true)
        probe.set(false)
        service.enabled = false
        XCTAssertFalse(probe.observing)
        XCTAssertEqual(service.status, CallStatus(enabled: false, active: []))
        probe.running = true
        XCTAssertNil(service.heldUntil(now: now))

        // Re-enabling while the camera is on means in use at once, without a callback.
        service.enabled = true
        XCTAssertEqual(service.status, CallStatus(enabled: true, active: [.camera]))
        probe.set(false)
        service.enabled = false
        service.enabled = true
        XCTAssertNil(service.heldUntil(now: now))
    }

    func testStatusCallbackOnlyOnChange() async {
        service.start()
        XCTAssertEqual(statuses, [.off]) // start publishes once
        service.enabled = true
        probe.set(true)
        probe.set(true) // spurious callback
        await service.refresh()
        probe.set(false)
        await service.refresh()
        service.graceSecs = 30
        XCTAssertEqual(statuses, [
            .off,
            CallStatus(enabled: true, active: []),
            CallStatus(enabled: true, active: [.camera]),
            CallStatus(enabled: true, active: []),
        ])
    }

    func testRefreshPicksUpAMissedChange() async {
        service.start()
        service.enabled = true
        probe.set(true, notify: false)
        XCTAssertNil(service.heldUntil(now: now))
        await service.refresh()
        XCTAssertEqual(service.status, CallStatus(enabled: true, active: [.camera]))
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))
        probe.set(false, notify: false)
        await service.refresh()
        XCTAssertEqual(service.heldUntil(now: now), now.addingTimeInterval(60))
    }

    func testRefreshWhileDisabledDoesNothing() async {
        service.start()
        probe.running = true
        await service.refresh()
        XCTAssertEqual(service.status, .off)
        XCTAssertNil(service.heldUntil(now: now))
    }

    func testDefaultInitUsesTheRealProbes() {
        let real = CallDetector()
        XCTAssertEqual(real.status, .off)
        XCTAssertNil(real.heldUntil(now: Date()))
    }

    /// The real probes only read "in use" flags: watching and reading must work unattended
    /// (no permission involved) and leave nothing behind.
    func testRealProbesWatchAndStopCleanly() {
        for probe in [CMIOCameraProbe(), CoreAudioMicrophoneProbe()] as [CallProbe] {
            probe.startObserving {}
            _ = probe.anyRunning()
            probe.stopObserving()
            probe.stopObserving()
        }
    }

    // MARK: Camera and microphone together

    private func makeBoth() -> (camera: FakeProbe, microphone: FakeProbe, detector: CallDetector) {
        let (camera, microphone) = (FakeProbe(), FakeProbe())
        let detector = CallDetector(probes: [.camera: camera, .microphone: microphone], clock: { [unowned self] in self.clock })
        detector.graceSecs = 60
        detector.enabled = true
        detector.start()
        return (camera, microphone, detector)
    }

    func testMicrophoneAloneCountsAsACall() {
        let (_, microphone, detector) = makeBoth()
        microphone.set(true)
        XCTAssertEqual(detector.status, CallStatus(enabled: true, active: [.microphone]))
        XCTAssertEqual(detector.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))
    }

    func testGraceStartsWhenTheLastDeviceGoesOff() {
        let (camera, microphone, detector) = makeBoth()
        camera.set(true)
        microphone.set(true)
        XCTAssertEqual(detector.status.active, [.camera, .microphone])
        advance(100)
        camera.set(false) // camera off, still talking
        XCTAssertEqual(detector.status.active, [.microphone])
        XCTAssertEqual(detector.heldUntil(now: now), now.addingTimeInterval(CallRules.recheck))
        advance(100)
        microphone.set(false)
        XCTAssertFalse(detector.status.inUse)
        XCTAssertEqual(detector.heldUntil(now: now), now.addingTimeInterval(60), "the grace counts from the last device")
        advance(60)
        XCTAssertNil(detector.heldUntil(now: now))
    }

    func testBothKindsAreWatchedOnlyWhileEnabled() {
        let (camera, microphone, detector) = makeBoth()
        XCTAssertTrue(camera.observing && microphone.observing)
        detector.enabled = false
        XCTAssertFalse(camera.observing || microphone.observing)
        XCTAssertEqual(detector.status, .off)
    }
}
