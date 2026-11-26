// Whether the sun is up where the user roughly is, without asking for their location. The
// Mac's time zone is named after a city (Europe/Warsaw), macOS ships that city's coordinates
// in its time zone database (`zone.tab`), and the height of the sun there follows from the
// date. No permission, no prompt, no network. The answer is off by up to about half an hour
// for somebody far from the city their time zone is named after (more in the few very wide
// zones), which is plenty for choosing a break idea. Pure rules first (unit tested in
// `SunRulesTests`), the part that reads the system after.

import Foundation

/// A point on the globe, in degrees: north and east are positive.
struct Place: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
}

enum SunRules {
    /// Sunrise and sunset are the moments the sun's centre is this many degrees under the
    /// horizon (its radius plus the bending of light in the air).
    static let horizon = -0.833

    /// How high the sun stands over the horizon at `place`, in degrees (negative: below it).
    /// The low-precision formulas of the Astronomical Almanac, good to about 0.01° this
    /// century. Polar day and night need no special case: the sun just stays over or under.
    static func elevation(at date: Date, place: Place) -> Double {
        let rad = Double.pi / 180
        // Days since 1 January 2000, 12:00 UTC.
        let days = date.timeIntervalSince1970 / 86_400 - 10_957.5
        let anomaly = (357.528 + 0.9856003 * days) * rad
        let eclipticLongitude = (280.460 + 0.9856474 * days + 1.915 * sin(anomaly) + 0.020 * sin(2 * anomaly)) * rad
        let tilt = (23.439 - 0.0000004 * days) * rad
        let declination = asin(sin(tilt) * sin(eclipticLongitude))
        let rightAscension = atan2(cos(tilt) * sin(eclipticLongitude), cos(eclipticLongitude))
        // Greenwich sidereal time as an angle, moved to the place's meridian.
        let hourAngle = (280.46061837 + 360.98564736629 * days + place.longitude) * rad - rightAscension
        let latitude = place.latitude * rad
        return asin(sin(latitude) * sin(declination) + cos(latitude) * cos(declination) * cos(hourAngle)) / rad
    }

    static func isUp(at date: Date, place: Place) -> Bool {
        elevation(at: date, place: place) > horizon
    }

    /// The city each time zone is named after, from the text of the time zone database's
    /// `zone.tab`: tab-separated country, coordinates, zone name (`PL	+5215+02100	Europe/Warsaw`).
    /// The table only knows a zone's current name, and macOS still uses some older ones
    /// (Asia/Calcutta, Europe/Kiev), so the renames in the database's `tzdata.zi`
    /// (`L Asia/Kolkata Asia/Calcutta`) are followed too.
    static func places(zoneTab: String, tzdata: String = "") -> [String: Place] {
        var places: [String: Place] = [:]
        for line in zoneTab.split(separator: "\n") where !line.hasPrefix("#") {
            let columns = line.split(separator: "\t")
            guard columns.count >= 3, let place = place(iso6709: columns[1]) else { continue }
            places[String(columns[2])] = place
        }
        for line in tzdata.split(separator: "\n") where line.hasPrefix("L ") {
            let words = line.split(separator: " ")
            guard words.count == 3, let place = places[String(words[1])], places[String(words[2])] == nil else { continue }
            places[String(words[2])] = place
        }
        return places
    }

    /// `+5215+02100` or `+404251-0740023`: latitude as ±DDMM or ±DDMMSS, then longitude as
    /// ±DDDMM or ±DDDMMSS.
    static func place(iso6709 text: Substring) -> Place? {
        guard let split = text.dropFirst().firstIndex(where: { $0 == "+" || $0 == "-" }),
              let latitude = degrees(text[..<split], degreeDigits: 2),
              let longitude = degrees(text[split...], degreeDigits: 3) else { return nil }
        return Place(latitude: latitude, longitude: longitude)
    }

    private static func degrees(_ part: Substring, degreeDigits: Int) -> Double? {
        let digits = part.dropFirst()
        guard part.first == "+" || part.first == "-",
              digits.count == degreeDigits + 2 || digits.count == degreeDigits + 4,
              digits.allSatisfy({ ("0"..."9").contains($0) }),
              let whole = Double(digits.prefix(degreeDigits)),
              let minutes = Double(digits.dropFirst(degreeDigits).prefix(2)) else { return nil }
        let seconds = Double(digits.dropFirst(degreeDigits + 2)) ?? 0
        return (part.first == "-" ? -1 : 1) * (whole + minutes / 60 + seconds / 3600)
    }
}

enum Sun {
    /// The time zone database macOS keeps up to date itself; world-readable.
    private static let zoneInfo = "/usr/share/zoneinfo"

    private static let places: [String: Place] = {
        guard let table = try? String(contentsOfFile: "\(zoneInfo)/zone.tab", encoding: .utf8) else {
            Log.warn("sun", "cannot read \(zoneInfo)/zone.tab; day and night are unknown")
            return [:]
        }
        let renames = (try? String(contentsOfFile: "\(zoneInfo)/tzdata.zi", encoding: .utf8)) ?? ""
        return SunRules.places(zoneTab: table, tzdata: renames)
    }()

    /// Whether the sun is up at `date` in the city the Mac's time zone is named after. `nil`
    /// when the zone names no city (UTC, GMT).
    static func isUp(at date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> Bool? {
        if let devOverride { return devOverride }
        return places[timeZone.identifier].map { SunRules.isUp(at: date, place: $0) }
    }

    /// `SME_DEV_SUN=up` or `down` (dev aid): the answer whatever the hour, to see the day or
    /// night ideas on demand.
    static var devOverride: Bool? {
        switch ProcessInfo.processInfo.environment["SME_DEV_SUN"]?.trimmingCharacters(in: .whitespaces) {
        case "up": true
        case "down": false
        default: nil
        }
    }
}
