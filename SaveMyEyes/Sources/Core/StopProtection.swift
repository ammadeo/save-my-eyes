// "Stop protection for 1–3 hours": the user's own pause, as a `PauseSource` like any other.
// It is also the smallest example of one: say when you hold breaks and what the menu should
// call it, and tell `onPauseChanged` when that changes. The hold, the pause icon in the menu
// bar and the menu's status all follow.

import Foundation

private enum T {
    static let label = L("Protection is stopped", "Ochrona wstrzymana")
    static let next = L("Your next break starts when protection is back on", "Następna przerwa zacznie się po wznowieniu ochrony")
}

@MainActor
final class StopProtection: PauseSource {
    var onPauseChanged: (() -> Void)?
    private(set) var until: Date?

    func stop(until: Date) {
        Log.info("stop", "protection stopped until \(ISO8601DateFormatter().string(from: until))")
        self.until = until
        onPauseChanged?()
    }

    /// Protection is back on before its time (the user started a break by hand).
    func resume() {
        guard until != nil else { return }
        Log.info("stop", "protection is back on")
        until = nil
        onPauseChanged?()
    }

    func pause(now: Date) -> Pause? {
        guard let until, now < until else { return nil }
        return Pause(holdsUntil: until, endsAt: until, symbol: "pause.fill", label: T.label, next: T.next)
    }

    func refresh() async {}
}
