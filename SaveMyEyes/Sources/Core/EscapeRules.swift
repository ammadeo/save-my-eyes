// The rules behind the break's escape hatch (PRODUCT.md › "Never trap"): however a cover
// goes wrong, the user can always leave it. Pure, so they can be unit-tested; the window
// layer (`Sources/Windows/BreakEscape.swift`, `CoverWindow`) applies them.
//
// Three layers, each independent of the one before:
// 1. The SwiftUI exit button on every cover. Each cover reports where its button is; if the
//    button is missing, off-screen or stuck for `fallbackAfter` seconds, the window shows a
//    native AppKit "Skip break" button that does not depend on SwiftUI at all.
// 2. A keyboard shortcut (Control-Option-Command-Escape) registered system-wide while a
//    cover is up, so a break can be skipped even when nothing on screen can be seen or
//    clicked (a display that is off, a cover drawn wrong, every Space hidden).
// 3. A watchdog thread: if the main thread stops answering for `watchdogLimit` seconds while
//    a cover is up, nothing in the app can close the cover, so the app relaunches itself
//    (the covers go away with the old process).

import CoreGraphics
import Foundation

enum EscapeRules {
    /// Seconds a cover's exit button may be missing before the native fallback shows. Long
    /// enough for the first render and the opening animation, short enough to never trap.
    static let fallbackAfter: TimeInterval = 3
    /// Seconds without an answer from the main thread before the watchdog relaunches the app.
    static let watchdogLimit = 20

    /// Virtual key code of Escape (`kVK_Escape`).
    static let shortcutKeyCode: UInt16 = 0x35
    /// Shown on the fallback button and in the exit buttons' tooltips.
    static let shortcutLabel = "⌃⌥⌘⎋"

    /// Whether a cover's exit button can be seen and clicked: it was laid out with a real
    /// size, entirely inside the cover, and is not mid-close (a click that did nothing).
    static func skipButtonReachable(frame: CGRect?, usable: Bool, in bounds: CGSize) -> Bool {
        guard usable, let frame, !frame.isNull, !frame.isInfinite,
              frame.width >= 1, frame.height >= 1, bounds.width >= 1, bounds.height >= 1
        else { return false }
        // One point of slack for rounding at the edges.
        return CGRect(origin: .zero, size: bounds).insetBy(dx: -1, dy: -1).contains(frame)
    }

    /// The fallback shows once the button has been unreachable for `fallbackAfter` seconds
    /// in a row (`unreachableSince` is when it last stopped being reachable, or when the cover
    /// opened if it never was).
    static func showsFallback(reachable: Bool, unreachableSince: Date?, now: Date) -> Bool {
        guard !reachable else { return false }
        guard let since = unreachableSince else { return true }
        return now.timeIntervalSince(since) >= fallbackAfter
    }
}

/// The watchdog's bookkeeping, one `tick()` per second on its own thread: a ping is sent to
/// the main thread only once the previous one was answered, so `limit` ticks in a row
/// without an answer mean the main thread has been stuck for about `limit` seconds. Counting
/// ticks instead of wall-clock time keeps system sleep from looking like a hang.
struct WatchdogCounter: Equatable {
    enum Step: Equatable {
        /// Send ping `n` to the main thread.
        case ping(Int)
        /// The last ping is still unanswered.
        case wait
        /// The main thread has not answered for `limit` ticks.
        case stalled
    }

    let limit: Int
    private(set) var sent = 0
    private(set) var answered = 0
    private(set) var misses = 0

    init(limit: Int = EscapeRules.watchdogLimit) {
        self.limit = max(1, limit)
    }

    mutating func tick() -> Step {
        if answered >= sent {
            misses = 0
            sent += 1
            return .ping(sent)
        }
        misses += 1
        return misses >= limit ? .stalled : .wait
    }

    /// The main thread ran ping `n`.
    mutating func pong(_ n: Int) {
        answered = max(answered, n)
    }
}
