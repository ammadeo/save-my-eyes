// Settings form shared by the menu's settings pane and the cover's settings card.
// Port of src/fixes.ts and src/composables/useSettingsForm.ts: a draft in seconds, clamped
// to the ranges the UI offers on save, with a bilingual "Fixing X from A to B" log.
// Nothing is persisted until `save()`.

import Foundation
import Observation

/// Form state in seconds; `longEvery` is the interval between long breaks in seconds
/// (a multiple of `every`), not the count the settings store.
struct SettingsDraft: Equatable {
    var every: Int {
        // Keep the long-break interval a multiple of the short-break interval.
        didSet { if every != oldValue { longEvery = Int(SettingsFormRules.fixLongEvery(Double(longEvery), every: every).value) } }
    }
    var shortLast: Int
    var longEvery: Int
    var longLast: Int
    /// Pause after a meeting ends before a held break fires, in seconds.
    var calendarGrace: Int
    var soundsUi: Bool
    var lang: Lang

    init(_ s: Settings) {
        every = s.breaks.every
        shortLast = s.breaks.short.last
        longEvery = s.breaks.long.every * s.breaks.every
        longLast = s.breaks.long.last
        calendarGrace = s.calendar.graceSecs
        soundsUi = s.sounds.ui
        lang = s.lang
    }
}

/// Port of legacy FixNumber: a chain of clamps that remembers the original.
struct FixNumber {
    let original: Double
    private(set) var value: Double

    init(_ original: Double) {
        self.original = original
        value = original
    }

    /// `Math.round` (halves toward +∞).
    private static func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    func min(_ m: Double) -> FixNumber { var c = self; c.value = Swift.max(value, m); return c }
    func max(_ m: Double) -> FixNumber { var c = self; c.value = Swift.min(value, m); return c }
    func round() -> FixNumber { var c = self; c.value = Self.jsRound(value); return c }
    func toClosest(_ step: Double) -> FixNumber { var c = self; c.value = Self.jsRound(value / step) * step; return c }
    var changed: Bool { value != original }
}

/// One clamp made by the form, in contract units (seconds; `longEvery` is a count of short
/// breaks and may be fractional before rounding).
struct FormFix: Equatable {
    let code: FixCode
    let from: Double
    let to: Double

    var asFix: Fix { Fix(code: code, from: Int(from.rounded()), to: Int(to.rounded())) }
}

enum SettingsFormRules {
    /// UI ranges (legacy ContentSettings), tighter than `Settings.validate`.
    static let everyMin = 5...30
    static let shortLastSec = 5...60
    static let longEveryMaxMin = 120
    static let longLastMin = 1...60
    static let calendarGraceMin = 0...15

    /// Snaps the long-break interval (seconds) to a multiple of `every` (seconds).
    static func fixLongEvery(_ secs: Double, every: Int) -> FixNumber {
        FixNumber(secs).round().toClosest(Double(every)).min(Double(every)).max(Double(longEveryMaxMin * 60))
    }

    /// Clamps the draft into settings; `base` supplies what the draft does not hold
    /// (voice sounds, `calendar.enabled`, which the toggle applies outside the draft).
    static func settings(from draft: SettingsDraft, base: Settings) -> (settings: Settings, fixes: [FormFix]) {
        var fixes: [FormFix] = []
        func track(_ code: FixCode, _ r: FixNumber, scale: Double = 1) -> Double {
            if r.changed { fixes.append(FormFix(code: code, from: r.original / scale, to: r.value / scale)) }
            return r.value
        }
        let every = track(.shortEvery, FixNumber(Double(draft.every)).round()
            .min(Double(everyMin.lowerBound * 60)).max(Double(everyMin.upperBound * 60)))
        let shortLast = track(.shortLast, FixNumber(Double(draft.shortLast)).round()
            .min(Double(shortLastSec.lowerBound)).max(Double(shortLastSec.upperBound)))
        let longEverySecs = track(.longEvery, fixLongEvery(Double(draft.longEvery), every: Int(every)), scale: every)
        let longLast = track(.longLast, FixNumber(Double(draft.longLast)).round()
            .min(Double(longLastMin.lowerBound * 60)).max(Double(longLastMin.upperBound * 60)))
        let grace = track(.calendarGrace, FixNumber(Double(draft.calendarGrace)).round().toClosest(60)
            .min(Double(calendarGraceMin.lowerBound * 60)).max(Double(calendarGraceMin.upperBound * 60)))

        var next = base
        next.breaks.every = Int(every)
        next.breaks.short.last = Int(shortLast)
        next.breaks.long.last = Int(longLast)
        next.breaks.long.every = Int((longEverySecs / every).rounded())
        next.sounds.ui = draft.soundsUi
        next.lang = draft.lang
        next.calendar.graceSecs = Int(grace)
        return (next, fixes)
    }

    private static let names: [FixCode: L] = [
        .shortEvery: L("short break every", "czas między krótkimi przerwami"),
        .shortLast: L("short break length", "długość krótkiej przerwy"),
        .longEvery: L("long break every", "czas między długimi przerwami"),
        .longLast: L("long break length", "długość długiej przerwy"),
        .calendarGrace: L("pause after a call", "wstrzymanie po rozmowie"),
    ]

    private static func formatSeconds(_ value: Int, lang: Lang) -> String {
        if value > 60 { return "\(Int((Double(value) / 60 + 0.5).rounded(.down))) min." }
        return "\(value) \(lang.pick(Strings.secondsSuffix))"
    }

    /// Bilingual log line for one fix. `every` (seconds) converts a `longEvery` count to time.
    static func message(code: FixCode, from: Double, to: Double, lang: Lang, every: Int) -> String {
        let scale = code == .longEvery ? Double(every) : 1
        let f = formatSeconds(Int((from * scale + 0.5).rounded(.down)), lang: lang)
        let t = formatSeconds(Int((to * scale + 0.5).rounded(.down)), lang: lang)
        let name = lang.pick(names[code]!)
        return lang == .pl ? "Naprawiam \(name) z \(f) na \(t)" : "Fixing \(name) from \(f) to \(t)"
    }

    static func message(_ fix: Fix, lang: Lang, every: Int) -> String {
        message(code: fix.code, from: Double(fix.from), to: Double(fix.to), lang: lang, every: every)
    }
}

struct SettingsSaveResult {
    let ok: Bool
    let fixes: [Fix]
    let messages: [String]
}

@Observable
@MainActor
final class SettingsForm {
    var draft: SettingsDraft
    private var baseline: SettingsDraft
    @ObservationIgnored private let model: AppModel

    var changed: Bool { draft != baseline }

    init(model: AppModel) {
        self.model = model
        let initial = SettingsDraft(model.settings)
        draft = initial
        baseline = initial
        followModel()
    }

    func reset() {
        draft = SettingsDraft(model.settings)
        baseline = draft
    }

    /// Another window saved: follow it unless the user is editing here.
    private func followModel() {
        withObservationTracking {
            _ = model.settings
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !self.changed { self.reset() }
                self.followModel()
            }
        }
    }

    /// Clamp to the UI ranges, persist through the model, reschedule keeping the windows.
    @discardableResult
    func save() -> SettingsSaveResult {
        let (next, formFixes) = SettingsFormRules.settings(from: draft, base: model.settings)
        let result = model.saveSettings(next)
        reset()
        model.setNextBreak(NextBreakOptions(keepWindows: true))
        let lang = model.lang
        let every = result.settings.breaks.every
        let messages = formFixes.map { SettingsFormRules.message(code: $0.code, from: $0.from, to: $0.to, lang: lang, every: every) }
            + result.fixes.map { SettingsFormRules.message($0, lang: lang, every: every) }
        return SettingsSaveResult(ok: result.error == nil, fixes: formFixes.map(\.asFix) + result.fixes, messages: messages)
    }
}
