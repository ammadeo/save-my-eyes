// The rules behind the break's escape hatch (PRODUCT.md › "Never trap"): a cover the user
// cannot leave is a bug, so the app stops rather than works around it. The covers go away
// with the process and macOS shows its crash dialog. Pure, so they can be unit-tested;
// `CoverWatchdog` and `WindowManager` apply them.
//
// - Each cover reports where its exit button is. With no cover offering a reachable button
//   for `exitMissingLimit` seconds in a row, the app crashes. One working cover is enough:
//   any Skip button closes every cover.
// - If an exit button ended the break but the covers stayed for `closeTimeout` seconds, the
//   app crashes.
// - If the main thread stops answering for `watchdogLimit` seconds, nothing in the app can
//   close a cover, so the app crashes.

import CoreGraphics
import Foundation

enum EscapeRules {
    /// Seconds with no reachable exit button before the app crashes. Long enough that a slow
    /// first render or a display change never kills the app.
    static let exitMissingLimit = 10
    /// Seconds a cover may stay up after its exit button ended the break. Closing is
    /// synchronous, so one second is already a failure.
    static let closeTimeout: TimeInterval = 1
    /// Seconds without an answer from the main thread before the app crashes.
    static let watchdogLimit = 20

    /// Whether a cover's exit button can be seen and clicked: it was laid out with a real
    /// size, entirely inside the cover.
    static func skipButtonReachable(frame: CGRect?, in bounds: CGSize) -> Bool {
        guard let frame, !frame.isNull, !frame.isInfinite,
              frame.width >= 1, frame.height >= 1, bounds.width >= 1, bounds.height >= 1
        else { return false }
        // One point of slack for rounding at the edges.
        return CGRect(origin: .zero, size: bounds).insetBy(dx: -1, dy: -1).contains(frame)
    }
}

/// The watchdog's bookkeeping, one `tick()` per second on its own thread: a ping is sent to
/// the main thread only once the previous one was answered, and the answer says whether a
/// cover still offers a way out. So `limit` ticks in a row without an answer mean the main
/// thread has been stuck for about `limit` seconds, and `exitMissingLimit` unreachable
/// answers in a row mean the user has had no exit for that long. Counting ticks and answers
/// instead of wall-clock time keeps system sleep from looking like a failure.
struct WatchdogCounter: Equatable {
    enum Step: Equatable {
        /// Send ping `n` to the main thread.
        case ping(Int)
        /// The last ping is still unanswered.
        case wait
        /// The main thread has not answered for `limit` ticks.
        case stalled
        /// The main thread answers, but no cover has had a reachable exit button.
        case trapped
    }

    let limit: Int
    let exitMissingLimit: Int
    private(set) var sent = 0
    private(set) var answered = 0
    private(set) var misses = 0
    private(set) var unreachable = 0

    init(limit: Int = EscapeRules.watchdogLimit, exitMissingLimit: Int = EscapeRules.exitMissingLimit) {
        self.limit = max(1, limit)
        self.exitMissingLimit = max(1, exitMissingLimit)
    }

    mutating func tick() -> Step {
        if unreachable >= exitMissingLimit { return .trapped }
        if answered >= sent {
            misses = 0
            sent += 1
            return .ping(sent)
        }
        misses += 1
        return misses >= limit ? .stalled : .wait
    }

    /// The main thread ran ping `n` and saw a cover with (or without) a reachable exit.
    mutating func pong(_ n: Int, exitReachable: Bool) {
        guard n > answered, n <= sent else { return }
        answered = n
        unreachable = exitReachable ? 0 : unreachable + 1
    }
}
