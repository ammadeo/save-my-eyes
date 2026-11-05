// Two languages, no plural tables beyond what the app needs. The language comes from
// settings (`Settings.lang`), not from the system locale, so strings are looked up through
// `Lang.pick` (or `AppModel.t`) rather than through String Catalogs.

import Foundation

/// One bilingual string.
struct L: Sendable {
    let en: String
    let pl: String
    init(_ en: String, _ pl: String) {
        self.en = en
        self.pl = pl
    }
}

extension Lang {
    func pick(_ l: L) -> String {
        switch self {
        case .en: l.en
        case .pl: l.pl
        }
    }

    var locale: Locale {
        Locale(identifier: self == .pl ? "pl_PL" : "en_GB")
    }
}

/// Strings shared by more than one surface. Surface-specific strings live next to their views.
enum Strings {
    static let title = L("Save My Eyes", "Save My Eyes")
    static let breakLong = L("long break", "długa przerwa")
    static let breakShort = L("short break", "krótka przerwa")
    static let settingsSave = L("Save changes", "Zapisz zmiany")
    static let secondsSuffix = L("sec.", "sek.")
    static let minutesSuffix = L("min.", "min.")

    // Tray menu (also relabelled when the language changes).
    static let trayOpen = L("Open Save My Eyes", "Otwórz Save My Eyes")
    static let trayLongBreak = L("Start a long break now", "Rozpocznij długą przerwę teraz")
    static let trayQuit = L("Quit", "Zakończ")

    /// Startup notification body.
    static func startupMessage(secs: Int, lang: Lang) -> String {
        let next = HumanDuration.formatted(seconds: secs, lang: lang)
        switch lang {
        case .en: return "Your eyes are protected. Next break will start in \(next)."
        case .pl: return "Dbamy o Twoje oczy. Następna przerwa rozpocznie się za \(next)."
        }
    }

    /// Polish plural form for a count: `one` (1), `few` (2-4 except 12-14), `many` (rest).
    static func plural(_ n: Int, one: String, few: String, many: String) -> String {
        if n == 1 { return one }
        let few_ = (2...4).contains(n % 10) && !(12...14).contains(n % 100)
        return few_ ? few : many
    }
}

/// Human durations in the style of date-fns `formatDistanceStrict` with `roundingMethod: floor`:
/// one unit, floored ("20 minutes", "1 hour", "45 seconds"), in English or Polish.
enum HumanDuration {
    static func formatted(seconds secsIn: Int, lang: Lang) -> String {
        let secs = max(0, secsIn)
        let (n, unit): (Int, Int) = secs < 60 ? (secs, 0) : secs < 3600 ? (secs / 60, 1) : (secs / 3600, 2)
        switch lang {
        case .en:
            let word: String
            switch unit {
            case 0: word = n == 1 ? "second" : "seconds"
            case 1: word = n == 1 ? "minute" : "minutes"
            default: word = n == 1 ? "hour" : "hours"
            }
            return "\(n) \(word)"
        case .pl:
            let word: String
            switch unit {
            case 0: word = Strings.plural(n, one: "sekunda", few: "sekundy", many: "sekund")
            case 1: word = Strings.plural(n, one: "minuta", few: "minuty", many: "minut")
            default: word = Strings.plural(n, one: "godzina", few: "godziny", many: "godzin")
            }
            return "\(n) \(word)"
        }
    }

    /// Floored distance between two dates ("2 minutes").
    static func between(_ from: Date, _ to: Date, lang: Lang) -> String {
        formatted(seconds: Int((to.timeIntervalSince(from)).rounded(.down)), lang: lang)
    }
}
