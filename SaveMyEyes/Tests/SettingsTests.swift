import XCTest
@testable import SaveMyEyes

/// Port of the Rust `settings.rs` tests: defaults, clamping, wire shape, persistence.
final class SettingsTests: XCTestCase {
    private func base() -> Settings { Settings(lang: .en) }

    func testDefaultsMatchLegacy() {
        let s = base()
        XCTAssertEqual(s.breaks.every, 1200)
        XCTAssertEqual(s.breaks.short.last, 20)
        XCTAssertEqual(s.breaks.long.last, 300)
        XCTAssertEqual(s.breaks.long.every, 3)
        XCTAssertTrue(s.sounds.ui && s.sounds.voice)
        XCTAssertFalse(s.calendar.enabled)
        XCTAssertEqual(s.calendar.graceSecs, 60)
    }

    func testDefaultsAreValid() {
        var s = base()
        XCTAssertTrue(s.validate().isEmpty)
    }

    func testClampsLowValues() {
        var s = base()
        s.breaks.every = 10
        s.breaks.short.last = 0
        s.breaks.long.every = 0
        s.breaks.long.last = 5
        let fixes = s.validate()
        XCTAssertEqual(fixes, [
            Fix(code: .shortEvery, from: 10, to: 60),
            Fix(code: .shortLast, from: 0, to: 1),
            Fix(code: .longEvery, from: 0, to: 1),
            Fix(code: .longLast, from: 5, to: 60),
        ])
        XCTAssertEqual(s.breaks.every, 60)
        XCTAssertEqual(s.breaks.short.last, 1)
        XCTAssertEqual(s.breaks.long.every, 1)
        XCTAssertEqual(s.breaks.long.last, 60)
    }

    func testClampsHighValues() {
        var s = base()
        s.breaks.every = 7200
        s.breaks.short.last = 61
        s.breaks.long.every = 31
        s.breaks.long.last = 3601
        s.calendar.graceSecs = 901
        let codes = s.validate().map { ($0.code, $0.to) }
        XCTAssertEqual(codes.map(\.0), [.shortEvery, .shortLast, .longEvery, .longLast, .calendarGrace])
        XCTAssertEqual(codes.map(\.1), [3600, 60, 30, 3600, 900])
        XCTAssertTrue(s.validate().isEmpty, "validate is idempotent")
    }

    func testBoundsAreInclusive() {
        var s = base()
        s.breaks.every = 60
        s.breaks.short.last = 60
        s.breaks.long.every = 30
        s.breaks.long.last = 3600
        s.calendar.graceSecs = 900
        XCTAssertTrue(s.validate().isEmpty)
        s.calendar.graceSecs = 0
        XCTAssertTrue(s.validate().isEmpty, "zero grace means fire at once")
    }

    func testCamelCaseWireShape() throws {
        let data = try JSONEncoder().encode(base())
        let v = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let expected: [String: Any] = [
            "breaks": ["every": 1200, "short": ["last": 20], "long": ["last": 300, "every": 3]],
            "sounds": ["ui": true, "voice": true],
            "lang": "en",
            "calendar": ["enabled": false, "graceSecs": 60],
        ]
        XCTAssertEqual(v as NSDictionary, expected as NSDictionary)
    }

    func testPartialJSONFillsDefaultsAndClamps() {
        let s = Settings.fromJSON(Data(#"{ "breaks": { "long": { "every": 99 } }, "lang": "pl" }"#.utf8))
        XCTAssertEqual(s.breaks.every, 1200)
        XCTAssertEqual(s.breaks.long.last, 300)
        XCTAssertEqual(s.breaks.long.every, 30)
        XCTAssertEqual(s.lang, .pl)
        XCTAssertTrue(s.sounds.voice)
        XCTAssertFalse(s.calendar.enabled)
        XCTAssertEqual(s.calendar.graceSecs, 60, "older files have no grace")
        let t = Settings.fromJSON(Data(#"{ "calendar": { "enabled": true, "graceSecs": 0 } }"#.utf8))
        XCTAssertTrue(t.calendar.enabled)
        XCTAssertEqual(t.calendar.graceSecs, 0)
    }

    func testCorruptJSONGivesDefaults() {
        XCTAssertEqual(Settings.fromJSON(Data("{ not json".utf8)).breaks, Settings.Breaks())
        XCTAssertEqual(Settings.fromJSON(Data(#"{ "lang": "de" }"#.utf8)).breaks, Settings.Breaks())
    }

    func testLangFromLocale() {
        XCTAssertEqual(Lang.fromLocale("pl-PL"), .pl)
        XCTAssertEqual(Lang.fromLocale("PL_pl.UTF-8"), .pl)
        XCTAssertEqual(Lang.fromLocale("en-GB"), .en)
        XCTAssertEqual(Lang.fromLocale(""), .en)
    }

    func testTauriSettingsFileIsReadAsIs() {
        // Exactly what the Tauri app wrote (serde pretty JSON).
        let json = """
        {
          "breaks": { "every": 900, "short": { "last": 30 }, "long": { "last": 420, "every": 2 } },
          "sounds": { "ui": false, "voice": true },
          "lang": "pl",
          "calendar": { "enabled": true, "graceSecs": 120 }
        }
        """
        let s = Settings.fromJSON(Data(json.utf8))
        XCTAssertEqual(s, Settings(
            breaks: .init(every: 900, short: .init(last: 30), long: .init(last: 420, every: 2)),
            sounds: .init(ui: false, voice: true),
            lang: .pl,
            calendar: .init(enabled: true, graceSecs: 120)
        ))
    }

    func testSaveAndLoadRoundtrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sme-settings-test-\(ProcessInfo.processInfo.processIdentifier)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let path = dir.appendingPathComponent("nested").appendingPathComponent("settings.json")
        var s = base()
        s.breaks.every = 900
        s.sounds.ui = false
        try s.save(to: path)
        XCTAssertEqual(Settings.load(from: path), s)
        XCTAssertEqual(Settings.load(from: dir.appendingPathComponent("missing.json")).breaks, Settings.Breaks())
    }

    func testDefaultURLIsTheTauriPath() {
        let url = Settings.defaultURL
        XCTAssertTrue(url.path.hasSuffix("/Library/Application Support/com.ammadeo.savemyeyes/settings-dev.json")
            || url.path.hasSuffix("/Library/Application Support/com.ammadeo.savemyeyes/settings.json"), url.path)
    }
}
