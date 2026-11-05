// Watches the break covers from a background queue while one is up (`WatchdogCounter` has the
// timing). A hung main thread cannot close its own covers, and a cover with no way out must
// not stay, so rather than leave the screens blocked the watchdog stops the app with a crash:
// macOS shows its "quit unexpectedly" dialog and the covers go away with the process.

import Darwin
import Foundation

final class CoverWatchdog: @unchecked Sendable {
    /// Everything below is touched only on this queue.
    private let queue = DispatchQueue(label: "com.ammadeo.savemyeyes.cover-watchdog", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var counter = WatchdogCounter()
    private var exitReachable: (@MainActor () -> Bool)?

    /// Stop the app on purpose. The reason goes to the log; the crash report has the stack,
    /// not this text (`fatalError` messages do not reach it).
    static func crash(_ reason: String) -> Never {
        let message = "Save My Eyes: \(reason)"
        Log.error("windows", message)
        fatalError(message)
    }

    /// `exitReachable` runs on the main thread: can the user still leave the covers?
    func start(exitReachable: @escaping @MainActor () -> Bool) {
        queue.async { [self] in
            guard timer == nil else { return }
            self.exitReachable = exitReachable
            counter = WatchdogCounter()
            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now() + 1, repeating: 1, leeway: .milliseconds(100))
            source.setEventHandler { [weak self] in self?.tick() }
            source.resume()
            timer = source
        }
    }

    func stop() {
        queue.async { [self] in
            timer?.cancel()
            timer = nil
            exitReachable = nil
        }
    }

    private func tick() {
        switch counter.tick() {
        case .ping(let n):
            guard let exitReachable else { return }
            DispatchQueue.main.async { [weak self] in
                let reachable = MainActor.assumeIsolated { exitReachable() }
                guard let self else { return }
                self.queue.async { self.counter.pong(n, exitReachable: reachable) }
            }
        case .wait:
            break
        case .stalled:
            failed("main thread unresponsive for \(counter.limit) s while a break cover was up")
        case .trapped:
            failed("no break cover had a reachable exit button for \(counter.exitMissingLimit) s")
        }
    }

    private func failed(_ reason: String) {
        if Self.isDebuggerAttached {
            // Paused at a breakpoint, not hung.
            counter = WatchdogCounter()
            return
        }
        Self.crash(reason)
    }

    private static var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
