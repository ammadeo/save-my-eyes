import XCTest
@testable import SaveMyEyes

/// Port of the duration/startup-message tests from the Rust `lib.rs`.
final class L10nTests: XCTestCase {
    func testDurationsEn() {
        XCTAssertEqual(HumanDuration.formatted(seconds: 1200, lang: .en), "20 minutes")
        XCTAssertEqual(HumanDuration.formatted(seconds: 119, lang: .en), "1 minute")
        XCTAssertEqual(HumanDuration.formatted(seconds: 8, lang: .en), "8 seconds")
        XCTAssertEqual(HumanDuration.formatted(seconds: 3600, lang: .en), "1 hour")
        XCTAssertEqual(HumanDuration.formatted(seconds: 2 * 3600, lang: .en), "2 hours")
    }

    func testDurationsPl() {
        XCTAssertEqual(HumanDuration.formatted(seconds: 60, lang: .pl), "1 minuta")
        XCTAssertEqual(HumanDuration.formatted(seconds: 22 * 60, lang: .pl), "22 minuty")
        XCTAssertEqual(HumanDuration.formatted(seconds: 12 * 60, lang: .pl), "12 minut")
        XCTAssertEqual(HumanDuration.formatted(seconds: 20 * 60, lang: .pl), "20 minut")
        XCTAssertEqual(HumanDuration.formatted(seconds: 8, lang: .pl), "8 sekund")
        XCTAssertEqual(HumanDuration.formatted(seconds: 3, lang: .pl), "3 sekundy")
        XCTAssertEqual(HumanDuration.formatted(seconds: 3 * 3600, lang: .pl), "3 godziny")
    }

    /// After "za" / "przez" Polish needs the accusative; only the singular forms change.
    func testAccusativePl() {
        func acc(_ secs: Int, _ lang: Lang = .pl) -> String {
            HumanDuration.accusative(HumanDuration.formatted(seconds: secs, lang: lang), lang: lang)
        }
        XCTAssertEqual(acc(1), "1 sekundę")
        XCTAssertEqual(acc(60), "1 minutę")
        XCTAssertEqual(acc(3600), "1 godzinę")
        XCTAssertEqual(acc(2 * 60), "2 minuty")
        XCTAssertEqual(acc(5 * 60), "5 minut")
        XCTAssertEqual(acc(21 * 60), "21 minut")
        XCTAssertEqual(acc(60, .en), "1 minute")
    }

    func testStartupMessages() {
        XCTAssertEqual(Strings.startupMessage(secs: 1200, lang: .en), "Your eyes are protected. Next break will start in 20 minutes.")
        XCTAssertEqual(Strings.startupMessage(secs: 1200, lang: .pl), "Twoje oczy są pod ochroną. Następna przerwa rozpocznie się za 20 minut.")
        XCTAssertEqual(Strings.startupMessage(secs: 60, lang: .pl), "Twoje oczy są pod ochroną. Następna przerwa rozpocznie się za 1 minutę.")
        XCTAssertEqual(Strings.startupMessage(secs: 60, lang: .en), "Your eyes are protected. Next break will start in 1 minute.")
    }
}
