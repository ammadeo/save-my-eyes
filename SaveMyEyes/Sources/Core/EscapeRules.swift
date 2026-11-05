// The rules behind the break's escape hatch (PRODUCT.md › "Never trap"): if a cover goes
// wrong, the user can still leave it. Pure, so they can be unit-tested; the window layer
// (`CoverWindow`, `CoverWatchdog`) applies them.
//
// - Each cover reports where its SwiftUI exit button is; if the button is missing,
//   off-screen or stuck for `fallbackAfter` seconds, the window shows a native AppKit
//   "Skip break" button that does not depend on SwiftUI at all.
// - If the main thread stops answering for `watchdogLimit` seconds while a cover is up,
//   nothing in the app can close the cover, so the watchdog crashes the app on purpose: the
//   covers go away with it and the crash report tells what happened. No attempt is made to
//   recover from that; it is a bug to report, not a state to live with.

import CoreGraphics
import Foundation

enum EscapeRules {
    /// Seconds a cover's exit button may be missing before the native fallback shows. Long
    /// enough for the first render and the opening animation, short enough to never trap.
    static let fallbackAfter: TimeInterval = 3
    /// Seconds without an answer from the main thread before the watchdog stops the app.
    static let watchdogLimit = 20

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
