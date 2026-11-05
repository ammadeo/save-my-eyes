// The parts of the break's escape hatch that do not depend on seeing the cover
// (`EscapeRules` has the full picture). Both run only while a break cover is up.
//
// - `EmergencyShortcut`: Control-Option-Command-Escape skips the break from anywhere. A
//   Carbon hot key is system-wide and needs no permission (unlike a global NSEvent monitor);
//   a local key monitor catches the same chord if the hot key could not be registered.
// - `CoverWatchdog`: relaunches the app if the main thread stops answering, since a hung
//   main thread cannot close its own covers.

import AppKit
import Carbon.HIToolbox
import Darwin

@MainActor
final class EmergencyShortcut {
    private let action: () -> Void
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var localMonitor: Any?

    /// `action` runs on the main thread each time the chord is pressed.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    var isActive: Bool { handler != nil || localMonitor != nil }

    func activate() {
        guard !isActive else { return }
        registerHotKey()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard EmergencyShortcut.matches(event) else { return event }
            MainActor.assumeIsolated { self?.fire(via: "key monitor") }
            return nil
        }
    }

    func deactivate() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        hotKey = nil
        handler = nil
        localMonitor = nil
    }

    private nonisolated static func matches(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        return event.keyCode == EscapeRules.shortcutKeyCode && mods == [.command, .option, .control]
    }

    private func fire(via source: String) {
        Log.warn("windows", "emergency shortcut \(EscapeRules.shortcutLabel) pressed (\(source))")
        // Next turn: the action disarms this shortcut, which must not happen inside the
        // Carbon handler or key monitor that is running.
        let action = self.action
        Task { @MainActor in action() }
    }

    private func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let shortcut = Unmanaged<EmergencyShortcut>.fromOpaque(context).takeUnretainedValue()
            // Carbon delivers application events on the main thread.
            MainActor.assumeIsolated { shortcut.fire(via: "hot key") }
            return OSStatus(noErr)
        }, 1, &spec, context, &handler)
        guard installed == noErr else {
            Log.error("windows", "emergency shortcut: InstallEventHandler failed (\(installed)), key monitor only")
            handler = nil
            return
        }
        // 'SMEe'
        let id = EventHotKeyID(signature: OSType(0x534D_4565), id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_Escape), UInt32(cmdKey | optionKey | controlKey),
                                             id, GetApplicationEventTarget(), 0, &hotKey)
        if registered != noErr {
            // Another app owns the chord; the key monitor still works while a cover is key.
            Log.error("windows", "emergency shortcut: RegisterEventHotKey failed (\(registered)), key monitor only")
            hotKey = nil
        }
    }
}

/// Watches the main thread from a background queue while a cover is up (`WatchdogCounter`
/// has the timing). On a stall it relaunches the app: the covers belong to this process and
/// go away with it, and the new instance schedules the next break as at login.
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
        Log.error("windows", "main thread unresponsive for \(counter.limit) s with a break cover up: relaunching to release the screens")
        let bundle = Bundle.main.bundleURL
        if bundle.pathExtension == "app" {
            let open = Process()
            open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            // -n: a new instance even though this one is still running; -g: in the background.
            open.arguments = ["-n", "-g", bundle.path]
            do { try open.run() } catch { Log.error("windows", "relaunch failed: \(error)") }
        }
        // `_exit`, not `exit`: the hung main thread may hold locks that atexit handlers need.
        _exit(EXIT_FAILURE)
    }

    private static var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
