import XCTest
@testable import SaveMyEyes

/// The sun's height from a date and a place, the time zone table, and the two together.
/// Sunrise and sunset times are the published ones for each city, with 20 minutes of margin.
final class SunRulesTests: XCTestCase {
    private let warsaw = Place(latitude: 52.25, longitude: 21.0)
    private let sydney = Place(latitude: -33.87, longitude: 151.21)
    private let tromso = Place(latitude: 69.65, longitude: 18.96)

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testTheSunStandsHighestAtNoonOnTheSolstice() {
        // 90° - latitude + the earth's tilt, at local solar noon (10:38 UTC in Warsaw).
        XCTAssertEqual(SunRules.elevation(at: utc(2026, 6, 21, 10, 38), place: warsaw), 61.19, accuracy: 0.3)
        XCTAssertEqual(SunRules.elevation(at: utc(2026, 12, 21, 10, 34), place: warsaw), 14.31, accuracy: 0.3)
    }

    /// Warsaw on 21 December: sunrise 06:43 UTC, sunset 14:25 UTC.
    func testAWinterDayInWarsaw() {
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 12, 21, 6, 20), place: warsaw))
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 12, 21, 7, 5), place: warsaw))
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 12, 21, 14, 5), place: warsaw))
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 12, 21, 14, 45), place: warsaw))
    }

    /// Warsaw on 21 June: sunrise 02:14 UTC, sunset 19:01 UTC.
    func testASummerDayInWarsaw() {
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 6, 21, 1, 50), place: warsaw))
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 6, 21, 2, 35), place: warsaw))
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 6, 21, 18, 40), place: warsaw))
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 6, 21, 19, 25), place: warsaw))
    }

    /// Sydney on 21 December: sunset 09:05 UTC, in the evening of its summer.
    func testTheSouthernHemisphereAndTheFarSideOfTheDateLine() {
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 12, 21, 8, 40), place: sydney))
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 12, 21, 9, 30), place: sydney))
    }

    func testPolarNightAndMidnightSun() {
        XCTAssertFalse(SunRules.isUp(at: utc(2026, 12, 21, 11), place: tromso), "noon in the polar night")
        XCTAssertTrue(SunRules.isUp(at: utc(2026, 6, 21, 23), place: tromso), "midnight under the midnight sun")
    }

    func testReadsTheTimeZoneTable() throws {
        let table = """
        # tz zone descriptions
        #country-\tcoordinates\tTZ\tcomments
        PL\t+5215+02100\tEurope/Warsaw
        US\t+404251-0740023\tAmerica/New_York\tEastern (most areas)
        AU\t-3352+15113\tAustralia/Sydney\tNew South Wales (most areas)
        XX\tsomewhere\tNowhere/Broken
        XX\t+52+021\tNowhere/Short
        """
        let places = SunRules.places(zoneTab: table)
        XCTAssertEqual(Set(places.keys), ["Europe/Warsaw", "America/New_York", "Australia/Sydney"])
        XCTAssertEqual(places["Europe/Warsaw"], Place(latitude: 52.25, longitude: 21))
        let newYork = try XCTUnwrap(places["America/New_York"])
        XCTAssertEqual(newYork.latitude, 40.7142, accuracy: 0.0001)
        XCTAssertEqual(newYork.longitude, -74.0064, accuracy: 0.0001)
        let sydney = try XCTUnwrap(places["Australia/Sydney"])
        XCTAssertEqual(sydney.latitude, -33.8667, accuracy: 0.0001)
        XCTAssertEqual(sydney.longitude, 151.2167, accuracy: 0.0001)
    }

    /// A zone macOS still calls by an older name gets the city of the zone it became.
    func testFollowsRenamedZones() {
        let table = "IN\t+2232+08822\tAsia/Kolkata\nPL\t+5215+02100\tEurope/Warsaw\n"
        let tzdata = """
        # version 2025b
        Z Asia/Kolkata 5:53:28 - LMT 1854 Jun 28
        L Asia/Kolkata Asia/Calcutta
        L Europe/Warsaw Poland
        L Etc/GMT GMT
        L Asia/Kolkata Europe/Warsaw
        """
        let places = SunRules.places(zoneTab: table, tzdata: tzdata)
        XCTAssertEqual(places["Asia/Calcutta"], places["Asia/Kolkata"])
        XCTAssertEqual(places["Poland"], Place(latitude: 52.25, longitude: 21))
        XCTAssertNil(places["GMT"], "a rename of a zone with no city has none either")
        XCTAssertEqual(places["Europe/Warsaw"], Place(latitude: 52.25, longitude: 21), "the table wins over a rename")
    }

    /// The table macOS ships, read the way the app reads it.
    func testTheSunWhereTheTimeZoneSaysTheUserIs() throws {
        try XCTSkipIf(Sun.devOverride != nil, "SME_DEV_SUN is set")
        let warsawZone = try XCTUnwrap(TimeZone(identifier: "Europe/Warsaw"))
        XCTAssertEqual(Sun.isUp(at: utc(2026, 12, 21, 11), timeZone: warsawZone), true)
        XCTAssertEqual(Sun.isUp(at: utc(2026, 12, 21, 20), timeZone: warsawZone), false)
        // 12:00 in India, under its older name.
        XCTAssertEqual(Sun.isUp(at: utc(2026, 12, 21, 6, 30), timeZone: try XCTUnwrap(TimeZone(identifier: "Asia/Calcutta"))), true)
        XCTAssertNil(Sun.isUp(at: utc(2026, 12, 21, 11), timeZone: try XCTUnwrap(TimeZone(identifier: "UTC"))), "UTC names no city")
    }
}
