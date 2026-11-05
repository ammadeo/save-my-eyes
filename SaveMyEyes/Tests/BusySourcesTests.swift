import XCTest
@testable import SaveMyEyes

/// Busy source stub: holds until a fixed date when set, or for `ahead` seconds from each ask
/// (a source with no known end, like a camera in use).
@MainActor
private final class FakeSource: BusySource {
    var until: Date?
    var ahead: TimeInterval?
    var refreshes = 0
    func heldUntil(now: Date) -> Date? { ahead.map { now.addingTimeInterval($0) } ?? until }
    func refresh() async { refreshes += 1 }
}

/// Calendar stub: always free, no EventKit, no timers outliving the test's model.
@MainActor
private final class FakeCalendar: CalendarServicing {
    var enabled = false
    var graceSecs = 0
    var onStatusChanged: ((CalendarStatus) -> Void)?
    var status: CalendarStatus { CalendarStatus(enabled: enabled, access: .granted, meeting: nil, syncedAt: nil) }
    func heldUntil(now: Date) -> Date? { nil }
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
    var active: Set<CallDevice> = []
    var onStatusChanged: ((CallStatus) -> Void)?
    var started = 0
    var status: CallStatus { CallStatus(enabled: enabled, active: enabled ? active : []) }
    func heldUntil(now: Date) -> Date? { status.inUse ? now.addingTimeInterval(30) : nil }
    func refresh() async {}
    func start() { started += 1 }
}

/// `BusySources` (calendar and call detection as one), a hold with no known end in the
/// scheduler, and the model's call-detection wiring.
@MainActor
final class BusySourcesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var dir: URL!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("sme-busy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: BusySources

    func testFreeWhenEverySourceIsFree() {
        XCTAssertNil(BusySources([]).heldUntil(now: now))
        XCTAssertNil(BusySources([FakeSource(), FakeSource()]).heldUntil(now: now))
    }

    func testWaitsForTheSourceThatHoldsLongest() {
        let (calendar, camera) = (FakeSource(), FakeSource())
        let both = BusySources([calendar, camera])
        camera.until = now.addingTimeInterval(30)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(30), "camera alone holds")
        calendar.until = now.addingTimeInterval(600)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(600), "the meeting ends later")
        camera.until = now.addingTimeInterval(900)
        XCTAssertEqual(both.heldUntil(now: now), now.addingTimeInterval(900), "the call runs over the meeting")
    }

    func testRefreshReachesEverySource() async {
        let (a, b) = (FakeSource(), FakeSource())
        await BusySources([a, b]).refresh()
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
        sch.busySource = BusySources([FakeSource(), camera])

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

    /// The scheduler asks the calendar and call detection together: a device in use alone
    /// holds a due break.
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
