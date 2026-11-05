// Startup sequence (port of `src-tauri/src/lib.rs` `setup`): model, window layer, status
// item, login item, first break, startup notification; wake → deadline check.

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var windowManager: WindowManager?
    private var statusItem: StatusItemController?
    private var wakeObserver: NSObjectProtocol?

    /// Unit tests run inside the app (TEST_HOST): no breaks, windows or permission prompts.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else {
            Log.info("startup", "running under XCTest, app startup skipped")
            return
        }
        NSApp.setActivationPolicy(.accessory)

        var calls = CallDetector()
        #if DEBUG
        if let secs = ProcessInfo.processInfo.environment["SME_DEV_CALL"].flatMap(TimeInterval.init) {
            Log.info("startup", "SME_DEV_CALL=\(secs): the microphone reads as in use for \(secs) s")
            calls = CallDetector(probes: [.microphone: DevCallProbe(secs: secs)])
        }
        #endif
        let model = AppModel(calendar: CalendarService(), calls: calls)
        let windows = WindowManager(model: model)
        model.windows = windows
        let statusItem = StatusItemController(model: model, windows: windows)
        windows.menuAnchor = statusItem.button
        model.onLanguageChanged = { [weak statusItem] lang in statusItem?.relabel(lang) }
        self.model = model
        self.windowManager = windows
        self.statusItem = statusItem

        LoginItem.enable()
        let state = model.start()
        let secs = state.scheduledAt.map { Int($0.timeIntervalSinceNow.rounded()) } ?? 0
        StartupNotification.post(secs: secs, lang: model.lang)

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak model] _ in
            MainActor.assumeIsolated {
                Log.info("startup", "woke from sleep, checking the break deadline")
                model?.checkDeadline()
            }
        }

        #if DEBUG
        // Dev aid: open the menu at startup (no synthetic status-item clicks on macOS).
        // `SME_DEV_OPEN_MENU=1` / `settings` / `stop-protection`.
        if let value = ProcessInfo.processInfo.environment["SME_DEV_OPEN_MENU"], !value.isEmpty {
            let pane = MenuPane(rawValue: value) ?? .menu
            // Next turn, once the status item button is in the menu bar.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak windows] in
                MainActor.assumeIsolated {
                    Log.info("windows", "SME_DEV_OPEN_MENU=\(value): opening the menu on \(pane.rawValue)")
                    windows?.openMenu(pane: pane)
                }
            }
        }
        #endif
    }

    /// Menu-bar agent: closing the last window must not quit the app.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

#if DEBUG
/// Dev aid (`SME_DEV_CALL=<secs>`): a microphone that reads as in use for the first `secs`
/// seconds, to see the paused state (menu-bar icon, menu status) without starting a call.
/// Needs "Pause breaks while camera or microphone is on" switched on.
private final class DevCallProbe: CallProbe {
    private let until: Date

    init(secs: TimeInterval) {
        until = Date().addingTimeInterval(secs)
    }

    func anyRunning() -> Bool { Date() < until }

    func startObserving(_ onChange: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + until.timeIntervalSinceNow + 0.1, execute: onChange)
    }

    func stopObserving() {}
}
#endif
