// Watches the main thread from a background queue while a break cover is up
// (`WatchdogCounter` has the timing). A hung main thread cannot close its own covers, so
// rather than leave the screens blocked, the watchdog stops the app with a crash: macOS shows
// its "quit unexpectedly" dialog, the covers go away with the process, and the crash report
// (with the reason below) can be sent to Apple.

import Darwin
import Foundation

final class CoverWatchdog: @unchecked Sendable {
    /// Everything below is touched only on this queue.
    private let queue = DispatchQueue(label: "com.ammadeo.savemyeyes.cover-watchdog", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var counter = WatchdogCounter()

    func start() {
        queue.async { [self] in
            guard timer == nil else { return }
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
        }
    }

    private func tick() {
        switch counter.tick() {
        case .ping(let n):
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.queue.async { self.counter.pong(n) }
            }
        case .wait:
            break
        case .stalled:
            stalled()
        }
    }

    private func stalled() {
        if Self.isDebuggerAttached {
            // Paused at a breakpoint, not hung.
            counter = WatchdogCounter()
            return
        }
        let reason = "Save My Eyes: main thread unresponsive for \(counter.limit) s while a break cover was up"
        Log.error("windows", reason)
        // The message lands in the crash report's "Application Specific Information".
        fatalError(reason)
    }

    private static var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
