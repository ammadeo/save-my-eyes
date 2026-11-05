import Observation
import XCTest
@testable import SaveMyEyes

/// Pause source stub: holds until a fixed date when set, or for `ahead` seconds from each ask
/// (a source with no known end, like a camera in use).
@MainActor
private final class FakeSource: PauseSource {
    var until: Date?
    var ahead: TimeInterval?
    var refreshes = 0
    var name = "test"
    var onPauseChanged: (() -> Void)?
    func pause(now: Date) -> Pause? {
        (ahead.map { now.addingTimeInterval($0) } ?? until).map { .holding(until: $0, label: name) }
    }
    func refresh() async { refreshes += 1 }
}

private final class Flag: @unchecked Sendable {
    var value = false
}

/// Calendar stub: always free, no EventKit, no timers outliving the test's model.
@MainActor
private final class FakeCalendar: CalendarServicing {
    var enabled = false
    var graceSecs = 0
    var onStatusChanged: ((CalendarStatus) -> Void)?
    var onPauseChanged: (() -> Void)?
    var status: CalendarStatus { CalendarStatus(enabled: enabled, access: .granted, meeting: nil, syncedAt: nil) }
    func pause(now: Date) -> Pause? { nil }
    func refresh() async {}
    func start() {}
    func requestAccess() async -> CalendarAccess { .granted }
    func openPrivacySettings() {}
}

/// Call detection stub for the model wiring.
@MainActor
private final class FakeCalls: CallDetecting {
    var enabled = false { didSet { if !enabled { active = [] } } }
    var graceSecs = 0
    var active: Set<CallDevice> = [] { didSet { onPauseChanged?() } }
    var onStatusChanged: ((CallStatus) -> Void)?
    var onPauseChanged: (() -> Void)?
    var started = 0
    var status: CallStatus { CallStatus(enabled: enabled, active: enabled ? active : []) }
    func pause(now: Date) -> Pause? { status.inUse ? .holding(until: now.addingTimeInterval(30), label: "call") : nil }
    func refresh() async {}
    func start() { started += 1 }
}

/// `PauseSources` (every way to pause breaks as one), a hold with no known end in the
/// scheduler, and the model's wiring: one pause drives the hold, the icon and the menu.
@MainActor
final class PauseSourcesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var dir: URL!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("sme-busy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: PauseSources

    func testFreeWhenEverySourceIsFree() {
        XCTAssertNil(PauseSources([]).heldUntil(now: now))
        XCTAssertNil(PauseSources([FakeSource(), FakeSource()]).heldUntil(now: now))
    }

    func testWaitsForTheSourceThatHoldsLongest() {
        let (calendar, camera) = (FakeSource(), FakeSource())
        let both = PauseSources([calendar, camera])
        camera.until = now.addingTimeInterval(30)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(30), "camera alone holds")
        calendar.until = now.addingTimeInterval(600)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(600), "the meeting ends later")
        camera.until = now.addingTimeInterval(900)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(900), "the call runs over the meeting")
    }

    /// The pause in effect is the whole answer of the source that holds longest, so the
    /// menu describes the same pause the scheduler obeys.
    func testThePauseInEffectIsTheOneThatHoldsLongest() {
        let (calendar, camera) = (FakeSource(), FakeSource())
        (calendar.name, camera.name) = ("meeting", "camera")
        let both = PauseSources([calendar, camera])
        camera.until = now.addingTimeInterval(30)
        calendar.until = now.addingTimeInterval(600)
        XCTAssertEqual(both.pause(now: now), .holding(until: now.addingTimeInterval(600), label: "meeting"))
    }

    func testAChangeInAnySourceIsPassedOn() {
        let (a, b) = (FakeSource(), FakeSource())
        let both = PauseSources([a, b])
        var changes = 0
        both.onPauseChanged = { changes += 1 }
        a.onPauseChanged?()
        b.onPauseChanged?()
        XCTAssertEqual(changes, 2)
    }

    func testRefreshReachesEverySource() async {
        let (a, b) = (FakeSource(), FakeSource())
        await PauseSources([a, b]).refresh()
        XCTAssertEqual([a.refreshes, b.refreshes], [1, 1])
    }

    // MARK: Scheduler with an open-ended hold

    /// A source that keeps answering "a bit later" holds the break across re-arms, and the
    /// break fires at the first ask after it lets go.
    func testOpenEndedHoldLastsWhileTheSourceKeepsAnswering() async {
        let settings = Settings(lang: .en)
        var fired: [Scheduler.Fired] = []
        let sch = Scheduler(settings: { settings })
        sch.onFire = { fired.append($0) }
        let camera = FakeSource()
        camera.ahead = 0.4
        sch.pauseSource = PauseSources([FakeSource(), camera])

        _ = sch.setNextBreak(NextBreakOptions(inSecs: 1))
        try? await Task.sleep(for: .milliseconds(2300))
        XCTAssertEqual(sch.phase, .idle)
        XCTAssertTrue(sch.heldForMeeting)
        XCTAssertTrue(fired.isEmpty)
        XCTAssertGreaterThanOrEqual(camera.refreshes, 3, "asked again at every re-arm")
        XCTAssertEqual(sch.breakIndex, 1, "a short hold keeps the break it held")

        camera.ahead = nil
        try? await Task.sleep(for: .milliseconds(900))
        XCTAssertEqual(sch.phase, .before)
        XCTAssertFalse(sch.heldForMeeting)
        XCTAssertEqual(fired, [.before])
    }

    // MARK: Model wiring

    private func makeModel(_ settings: Settings, calls: FakeCalls) throws -> AppModel {
        let url = dir.appendingPathComponent("settings.json")
        try settings.save(to: url)
        return AppModel(settingsURL: url, calendar: FakeCalendar(), calls: calls)
    }

    func testModelConfiguresCallDetectionFromSettings() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en, calendar: .init(enabled: false, graceSecs: 120), calls: .init(enabled: true)), calls: calls)
        XCTAssertTrue(calls.enabled)
        XCTAssertEqual(calls.graceSecs, 120, "the pause after a call is shared with the calendar")
        XCTAssertEqual(model.callStatus, CallStatus(enabled: true, active: []))
        XCTAssertEqual(calls.started, 0)
        model.start()
        XCTAssertEqual(calls.started, 1)
    }

    func testCallsToggleAppliesAtOnceAndPersists() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en), calls: calls)
        XCTAssertFalse(calls.enabled)

        XCTAssertEqual(model.setCallsEnabled(true), CallStatus(enabled: true, active: []))
        XCTAssertTrue(calls.enabled)
        XCTAssertTrue(model.settings.calls.enabled)
        XCTAssertTrue(Settings.load(from: dir.appendingPathComponent("settings.json")).calls.enabled)

        calls.active = [.microphone]
        calls.onStatusChanged?(calls.status)
        XCTAssertEqual(model.callStatus.active, [.microphone], "the detector's changes reach the views")

        XCTAssertEqual(model.setCallsEnabled(false), .off)
        XCTAssertFalse(model.settings.calls.enabled)
    }

    func testSavingSettingsUpdatesTheCallGrace() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en), calls: calls)
        var next = model.settings
        next.calendar.graceSecs = 300
        model.saveSettings(next)
        XCTAssertEqual(calls.graceSecs, 300)
    }

    // MARK: The model's pause: what the menu-bar icon and the menu's status show

    func testNoPauseWhenNothingHolds() throws {
        let model = try makeModel(Settings(lang: .en), calls: FakeCalls())
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        XCTAssertNil(model.pause(now: Date()))
    }

    /// Any source that holds breaks shows as the pause, with nothing written for it in the model.
    func testASourceThatHoldsIsThePause() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en, calls: .init(enabled: true)), calls: calls)
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        calls.active = [.camera]
        XCTAssertEqual(model.pause(now: Date())?.label, L(verbatim: "call"))
        calls.active = []
        XCTAssertNil(model.pause(now: Date()))
    }

    func testABreakOnScreenIsNotAPause() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en, calls: .init(enabled: true)), calls: calls)
        calls.active = [.camera]
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        model.startBreak()
        XCTAssertNil(model.pause(now: Date()))
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        XCTAssertNotNil(model.pause(now: Date()))
    }

    /// A source's change reaches whoever observes the model's pause (the status item).
    func testAPauseChangeIsObservable() throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en, calls: .init(enabled: true)), calls: calls)
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        let changed = Flag()
        withObservationTracking { _ = model.pause(now: Date()) } onChange: { changed.value = true }
        calls.active = [.microphone]
        XCTAssertTrue(changed.value)
    }

    // MARK: Stop protection, a pause source like the others

    func testStopProtectionSource() {
        let stop = StopProtection()
        var changes = 0
        stop.onPauseChanged = { changes += 1 }
        XCTAssertNil(stop.pause(now: now))

        stop.stop(until: now.addingTimeInterval(3600))
        XCTAssertEqual(stop.pause(now: now)?.holdsUntil, now.addingTimeInterval(3600))
        XCTAssertEqual(stop.pause(now: now)?.endsAt, now.addingTimeInterval(3600))
        XCTAssertNil(stop.pause(now: now.addingTimeInterval(3600)), "over at its time")

        stop.resume()
        XCTAssertNil(stop.pause(now: now))
        XCTAssertEqual(changes, 2)
    }

    func testStoppingProtectionPausesAndSchedulesALongBreak() throws {
        let model = try makeModel(Settings(lang: .en), calls: FakeCalls())
        model.pauseProtection(hours: 2)
        let pause = try XCTUnwrap(model.pause(now: Date()))
        XCTAssertEqual(pause.holdsUntil.timeIntervalSinceNow, 7200, accuracy: 5)
        XCTAssertTrue(model.breakState.isLong)
        XCTAssertEqual(try XCTUnwrap(model.breakState.scheduledAt).timeIntervalSinceNow, 7200, accuracy: 5)
    }

    /// Rescheduling (a settings save) does not quietly end the stop: the earlier break is held.
    func testStoppedProtectionSurvivesAReschedule() async throws {
        let model = try makeModel(Settings(lang: .en), calls: FakeCalls())
        model.pauseProtection(hours: 1)
        model.setNextBreak(NextBreakOptions(inSecs: 1, keepWindows: true))
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertEqual(model.breakState.phase, .idle)
        XCTAssertTrue(model.breakState.heldForMeeting)
        XCTAssertNotNil(model.pause(now: Date()))
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
    }

    func testStartingABreakByHandEndsTheStop() throws {
        let model = try makeModel(Settings(lang: .en), calls: FakeCalls())
        model.pauseProtection(hours: 1)
        model.startLongBreakNow()
        XCTAssertEqual(model.breakState.phase, .active)
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
        XCTAssertNil(model.pause(now: Date()))
    }

    /// The scheduler asks every source together: a device in use alone holds a due break.
    func testDeviceInUseHoldsADueBreak() async throws {
        let calls = FakeCalls()
        let model = try makeModel(Settings(lang: .en, calls: .init(enabled: true)), calls: calls)
        calls.active = [.camera]
        model.setNextBreak(NextBreakOptions(inSecs: 1))
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertEqual(model.breakState.phase, .idle)
        XCTAssertTrue(model.breakState.heldForMeeting)
        model.setNextBreak(NextBreakOptions(inSecs: 3600))
    }
}
