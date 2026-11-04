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

    func testStartupMessages() {
        XCTAssertEqual(Strings.startupMessage(secs: 1200, lang: .en), "Your eyes are protected. Next break will start in 20 minutes.")
        XCTAssertEqual(Strings.startupMessage(secs: 1200, lang: .pl), "Dbamy o Twoje oczy. Następna przerwa rozpocznie się za 20 minut.")
    }
}
