// Pure rules for call detection: how long a due break waits while a camera or microphone is
// in use or just went off. No system APIs here; unit tested in `CallRulesTests`.

import Foundation

enum CallRules {
    /// A device cannot say when it will go off, so while one is in use the break is held this
    /// long and the scheduler asks again (after a `refresh()`).
    static let recheck: TimeInterval = 30

    /// When a break due at `now` should fire instead: `now + recheck` while a device is in
    /// use, the end of the grace period while inside it after the last one went off at
    /// `offAt`, otherwise `nil` (fire now).
    static func heldUntil(now: Date, inUse: Bool, offAt: Date?, grace: TimeInterval) -> Date? {
        if inUse { return now.addingTimeInterval(recheck) }
        guard let offAt else { return nil }
        let end = offAt.addingTimeInterval(grace)
        return now < end ? end : nil
    }
}
