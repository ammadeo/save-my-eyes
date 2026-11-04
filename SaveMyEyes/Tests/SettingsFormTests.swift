import XCTest
@testable import SaveMyEyes

@MainActor
final class SettingsFormTests: XCTestCase {
    private var dir: URL!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("sme-form-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeModel(_ settings: Settings = Settings(lang: .en)) throws -> AppModel {
        let url = dir.appendingPathComponent("settings.json")
        try settings.save(to: url)
        return AppModel(settingsURL: url, calendar: CalendarService())
    }

    private func base(enabled: Bool = true, grace: Int = 60) -> Settings {
        Settings(lang: .en, calendar: .init(enabled: enabled, graceSecs: grace))
    }

    private func withGrace(_ grace: Int, from: Settings? = nil) -> (settings: Settings, fixes: [FormFix]) {
        let b = from ?? base()
        var draft = SettingsDraft(b)
        draft.calendarGrace = grace
        return SettingsFormRules.settings(from: draft, base: b)
    }

    // MARK: Port of fixes.spec.ts

    func testGraceRoundTrips() {
        let s = base(grace: 300)
        XCTAssertEqual(SettingsDraft(s).calendarGrace, 300)
        let r = SettingsFormRules.settings(from: SettingsDraft(s), base: s)
        XCTAssertEqual(r.settings, s)
        XCTAssertEqual(r.fixes, [])
    }

    func testGraceClampsAboveFifteenMinutes() {
        let r = withGrace(1000)
        XCTAssertEqual(r.settings.calendar.graceSecs, 900)
        XCTAssertEqual(r.fixes, [FormFix(code: .calendarGrace, from: 1000, to: 900)])
    }

    func testGraceSnapsToWholeMinutes() {
        XCTAssertEqual(withGrace(90).settings.calendar.graceSecs, 120)
        XCTAssertEqual(withGrace(89).settings.calendar.graceSecs, 60)
        XCTAssertEqual(withGrace(89).fixes, [FormFix(code: .calendarGrace, from: 89, to: 60)])
    }

    func testGraceClampsBelowZeroKeepsZero() {
        XCTAssertEqual(withGrace(-30).settings.calendar.graceSecs, 0)
        let r = withGrace(0)
        XCTAssertEqual(r.settings.calendar.graceSecs, 0)
        XCTAssertEqual(r.fixes, [])
    }

    func testKeepsCalendarEnabledFromBase() {
        let r = withGrace(180, from: base(enabled: false))
        XCTAssertEqual(r.settings.calendar, Settings.CalendarSettings(enabled: false, graceSecs: 180))
    }

    func testGraceMessageInBothLanguages() {
        XCTAssertEqual(SettingsFormRules.message(code: .calendarGrace, from: 1000, to: 900, lang: .en, every: 1200),
                       "Fixing pause after a call from 17 min. to 15 min.")
        XCTAssertEqual(SettingsFormRules.message(code: .calendarGrace, from: 1000, to: 900, lang: .pl, every: 1200),
                       "Naprawiam wstrzymanie po rozmowie z 17 min. na 15 min.")
    }

    // MARK: Clamping and snapping

    func testClampsToUIRanges() {
        let s = base()
        var draft = SettingsDraft(s)
        draft.every = 2 * 60 // below 5 min
        draft.shortLast = 10
        draft.longLast = 90 * 60 // above 60 min
        let r = SettingsFormRules.settings(from: draft, base: s)
        XCTAssertEqual(r.settings.breaks.every, 300)
        XCTAssertEqual(r.settings.breaks.short.last, 10)
        XCTAssertEqual(r.settings.breaks.long.last, 3600)
        XCTAssertEqual(r.fixes.map(\.code), [.shortEvery, .longLast])
    }

    func testShortLastBelowRangeIsFixed() {
        var draft = SettingsDraft(base())
        draft.shortLast = 2
        let r = SettingsFormRules.settings(from: draft, base: base())
        XCTAssertEqual(r.settings.breaks.short.last, 5)
        XCTAssertEqual(r.fixes, [FormFix(code: .shortLast, from: 2, to: 5)])
    }

    func testLongEverySnapsToMultipleOfEvery() {
        var draft = SettingsDraft(base())
        XCTAssertEqual(draft.longEvery, 3600)
        draft.longEvery = 50 * 60 // 2.5 × 20 min → 60 min (Math.round halves up)
        let r = SettingsFormRules.settings(from: draft, base: base())
        XCTAssertEqual(r.settings.breaks.long.every, 3)
        XCTAssertEqual(r.fixes, [FormFix(code: .longEvery, from: 2.5, to: 3)])
        XCTAssertEqual(r.fixes.first?.asFix.code, .longEvery)
    }

    func testLongEveryCappedAt120Minutes() {
        var draft = SettingsDraft(base())
        draft.every = 25 * 60
        draft.longEvery = 200 * 60
        let r = SettingsFormRules.settings(from: draft, base: base())
        // 120 min is not a multiple of 25 min; the cap wins after snapping, as in the legacy form.
        XCTAssertEqual(r.settings.breaks.every, 1500)
        XCTAssertLessThanOrEqual(r.settings.breaks.long.every * r.settings.breaks.every, 120 * 60 + 1500)
    }

    func testChangingEverySnapsDraftLongEvery() {
        var draft = SettingsDraft(base())
        draft.every = 25 * 60 // 60 min → closest multiple of 25 min is 50 min
        XCTAssertEqual(draft.longEvery, 50 * 60)
        draft.every = 30 * 60
        XCTAssertEqual(draft.longEvery, 60 * 60)
    }

    // MARK: Messages

    func testMessagesRenderSecondsAndMinutes() {
        XCTAssertEqual(SettingsFormRules.message(code: .shortLast, from: 10, to: 60, lang: .en, every: 1200),
                       "Fixing short break length from 10 sec. to 60 sec.")
        XCTAssertEqual(SettingsFormRules.message(code: .shortEvery, from: 10, to: 60, lang: .en, every: 1200),
                       "Fixing short break every from 10 sec. to 60 sec.")
        XCTAssertEqual(SettingsFormRules.message(code: .shortLast, from: 10, to: 60, lang: .pl, every: 1200),
                       "Naprawiam długość krótkiej przerwy z 10 sek. na 60 sek.")
    }

    func testLongEveryMessageRendersAsMinutes() {
        XCTAssertEqual(SettingsFormRules.message(code: .longEvery, from: 2.5, to: 3, lang: .en, every: 1200),
                       "Fixing long break every from 50 min. to 60 min.")
        XCTAssertEqual(SettingsFormRules.message(Fix(code: .longEvery, from: 40, to: 30), lang: .pl, every: 600),
                       "Naprawiam czas między długimi przerwami z 400 min. na 300 min.")
    }

    // MARK: Form

    func testFormTracksChangesAndResets() throws {
        let model = try makeModel()
        let form = SettingsForm(model: model)
        XCTAssertFalse(form.changed)
        form.draft.shortLast = 30
        XCTAssertTrue(form.changed)
        form.reset()
        XCTAssertFalse(form.changed)
        XCTAssertEqual(form.draft.shortLast, 20)
    }

    func testSaveClampsPersistsAndReportsFixes() throws {
        let model = try makeModel()
        let form = SettingsForm(model: model)
        form.draft.shortLast = 2
        form.draft.longLast = 45 * 60
        let result = form.save()
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.fixes, [Fix(code: .shortLast, from: 2, to: 5)])
        XCTAssertEqual(result.messages, ["Fixing short break length from 2 sec. to 5 sec."])
        XCTAssertEqual(model.settings.breaks.short.last, 5)
        XCTAssertEqual(model.settings.breaks.long.last, 45 * 60)
        XCTAssertFalse(form.changed)
        // Persisted.
        let reloaded = Settings.load(from: dir.appendingPathComponent("settings.json"))
        XCTAssertEqual(reloaded.breaks.long.last, 45 * 60)
    }

    func testSaveWithoutFixesHasNoMessages() throws {
        let model = try makeModel()
        let form = SettingsForm(model: model)
        form.draft.soundsUi = false
        form.draft.lang = .pl
        let result = form.save()
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.messages, [])
        XCTAssertFalse(model.settings.sounds.ui)
        XCTAssertEqual(model.lang, .pl)
    }

    func testFollowsModelWhenUnchanged() async throws {
        let model = try makeModel()
        let form = SettingsForm(model: model)
        let other = SettingsForm(model: model)
        other.draft.shortLast = 45
        other.save()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(form.draft.shortLast, 45)
        XCTAssertFalse(form.changed)
    }

    func testKeepsEditsWhenAnotherWindowSaves() async throws {
        let model = try makeModel()
        let form = SettingsForm(model: model)
        form.draft.longLast = 10 * 60
        let other = SettingsForm(model: model)
        other.draft.shortLast = 45
        other.save()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(form.draft.longLast, 10 * 60)
        XCTAssertEqual(form.draft.shortLast, 20)
        XCTAssertTrue(form.changed)
    }
}
