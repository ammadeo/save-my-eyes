// User settings: defaults, clamping validation and JSON persistence.
//
// The JSON shape and the file location are those of the Tauri app (camelCase keys,
// `~/Library/Application Support/com.ammadeo.savemyeyes/settings.json`), so an existing
// install keeps its settings. Missing keys take defaults; an unreadable file means defaults.

import Foundation

enum Lang: String, Codable, CaseIterable, Sendable {
    case en
    case pl

    /// `pl`, `pl-PL`, `PL_pl.UTF-8` → `.pl`; anything else → `.en`.
    static func fromLocale(_ locale: String) -> Lang {
        locale.lowercased().hasPrefix("pl") ? .pl : .en
    }

    static var system: Lang {
        fromLocale(Locale.preferredLanguages.first ?? Locale.current.identifier)
    }
}

struct Settings: Codable, Equatable, Sendable {
    var breaks = Breaks()
    var sounds = Sounds()
    var lang: Lang = .system
    var calendar = CalendarSettings()

    struct Breaks: Codable, Equatable, Sendable {
        /// Seconds between breaks.
        var every = 20 * 60
        var short = Short()
        var long = Long()

        struct Short: Codable, Equatable, Sendable {
            /// Length in seconds.
            var last = 20
            init(last: Int = 20) { self.last = last }
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                last = try c.decodeIfPresent(Int.self, forKey: .last) ?? 20
            }
        }

        struct Long: Codable, Equatable, Sendable {
            /// Length in seconds.
            var last = 5 * 60
            /// Every n-th break is long.
            var every = 3
            init(last: Int = 5 * 60, every: Int = 3) {
                self.last = last
                self.every = every
            }
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                last = try c.decodeIfPresent(Int.self, forKey: .last) ?? 5 * 60
                every = try c.decodeIfPresent(Int.self, forKey: .every) ?? 3
            }
        }

        init(every: Int = 20 * 60, short: Short = Short(), long: Long = Long()) {
            self.every = every
            self.short = short
            self.long = long
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            every = try c.decodeIfPresent(Int.self, forKey: .every) ?? 20 * 60
            short = try c.decodeIfPresent(Short.self, forKey: .short) ?? Short()
            long = try c.decodeIfPresent(Long.self, forKey: .long) ?? Long()
        }
    }

    struct Sounds: Codable, Equatable, Sendable {
        var ui = true
        var voice = true
        init(ui: Bool = true, voice: Bool = true) {
            self.ui = ui
            self.voice = voice
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            ui = try c.decodeIfPresent(Bool.self, forKey: .ui) ?? true
            voice = try c.decodeIfPresent(Bool.self, forKey: .voice) ?? true
        }
    }

    struct CalendarSettings: Codable, Equatable, Sendable {
        /// Hold breaks while the macOS calendar shows a meeting.
        var enabled = false
        /// Seconds after a meeting ends before a held break fires; 0 means right away.
        var graceSecs = 60
        init(enabled: Bool = false, graceSecs: Int = 60) {
            self.enabled = enabled
            self.graceSecs = graceSecs
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
            graceSecs = try c.decodeIfPresent(Int.self, forKey: .graceSecs) ?? 60
        }
    }

    init(breaks: Breaks = Breaks(), sounds: Sounds = Sounds(), lang: Lang = .system, calendar: CalendarSettings = CalendarSettings()) {
        self.breaks = breaks
        self.sounds = sounds
        self.lang = lang
        self.calendar = calendar
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        breaks = try c.decodeIfPresent(Breaks.self, forKey: .breaks) ?? Breaks()
        sounds = try c.decodeIfPresent(Sounds.self, forKey: .sounds) ?? Sounds()
        lang = try c.decodeIfPresent(Lang.self, forKey: .lang) ?? .system
        calendar = try c.decodeIfPresent(CalendarSettings.self, forKey: .calendar) ?? CalendarSettings()
    }
}

// MARK: - Validation

/// Which setting a `Fix` clamped. Raw values are the wire names the old frontend used.
enum FixCode: String, Equatable, Sendable {
    case shortEvery
    case shortLast
    case longEvery
    case longLast
    case calendarGrace
}

/// One clamped value, reported back so the UI can explain the change.
struct Fix: Equatable, Sendable {
    let code: FixCode
    let from: Int
    let to: Int
}

extension Settings {
    /// Inclusive legal ranges (the UI offers tighter ones, see the settings form).
    static let everyRange = 60...(60 * 60)
    static let shortLastRange = 1...60
    static let longLastRange = 60...(60 * 60)
    static let longEveryRange = 1...30
    static let calendarGraceRange = 0...(15 * 60)

    /// Clamp every numeric field into its legal range; returns what changed.
    @discardableResult
    mutating func validate() -> [Fix] {
        var fixes: [Fix] = []
        func clamp(_ value: inout Int, _ range: ClosedRange<Int>, _ code: FixCode) {
            let to = min(max(value, range.lowerBound), range.upperBound)
            if to != value {
                fixes.append(Fix(code: code, from: value, to: to))
                value = to
            }
        }
        clamp(&breaks.every, Settings.everyRange, .shortEvery)
        clamp(&breaks.short.last, Settings.shortLastRange, .shortLast)
        clamp(&breaks.long.every, Settings.longEveryRange, .longEvery)
        clamp(&breaks.long.last, Settings.longLastRange, .longLast)
        clamp(&calendar.graceSecs, Settings.calendarGraceRange, .calendarGrace)
        return fixes
    }

    /// Parse and validate; anything unreadable yields defaults.
    static func fromJSON(_ data: Data) -> Settings {
        var s: Settings
        do {
            s = try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            Log.warn("settings", "corrupt settings file, using defaults: \(error)")
            s = Settings()
        }
        s.validate()
        return s
    }

    static func load(from url: URL) -> Settings {
        guard let data = try? Data(contentsOf: url) else { return Settings() }
        return fromJSON(data)
    }

    func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: url, options: .atomic)
    }

    /// `~/Library/Application Support/com.ammadeo.savemyeyes/settings.json`
    /// (`settings-dev.json` in debug builds), the path the Tauri app used.
    static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        #if DEBUG
        let file = "settings-dev.json"
        #else
        let file = "settings.json"
        #endif
        return support.appendingPathComponent("com.ammadeo.savemyeyes").appendingPathComponent(file)
    }
}
