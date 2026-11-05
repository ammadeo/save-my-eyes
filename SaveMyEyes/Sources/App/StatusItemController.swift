// Menu-bar status item (port of `src-tauri/src/tray.rs`): template icon, left click toggles
// the menu popover, right click (or control-click) shows Open / Start long break now / Quit.
// While breaks are on hold (`AppModel.pause`, whatever the source) the icon's pupil turns into pause bars.

import AppKit
import Observation

@MainActor
final class StatusItemController: NSObject {
    private let item: NSStatusItem
    private let model: AppModel
    private let windows: WindowManager
    private let menu = NSMenu()
    private let openItem = NSMenuItem()
    private let longBreakItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var paused = false
    private var pauseEnd: Timer?

    var button: NSStatusBarButton? { item.button }

    init(model: AppModel, windows: WindowManager) {
        self.model = model
        self.windows = windows
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = item.button {
            button.target = self
            button.action = #selector(clicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        for (entry, action) in [(openItem, #selector(openMenu)), (longBreakItem, #selector(startLongBreak)), (quitItem, #selector(quit))] {
            entry.target = self
            entry.action = action
        }
        menu.addItem(openItem)
        menu.addItem(longBreakItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        relabel(model.lang)
        trackPause()
        Log.info("tray", "status item ready")
    }

    /// Re-label the right-click menu and the button after a language change.
    func relabel(_ lang: Lang) {
        openItem.title = lang.pick(Strings.trayOpen)
        longBreakItem.title = lang.pick(Strings.trayLongBreak)
        quitItem.title = lang.pick(Strings.trayQuit)
        show(paused: paused)
    }

    /// Show whether breaks are on hold, and look again whenever the model changes.
    private func trackPause() {
        let pause = withObservationTracking {
            model.pause(now: Date())
        } onChange: { [weak self] in
            // Fires before the new value is set: read it on the next turn.
            Task { @MainActor in self?.trackPause() }
        }
        if (pause != nil) != paused {
            Log.info("tray", pause != nil ? "breaks are on hold, showing the pause icon" : "breaks are back on, showing the normal icon")
        }
        show(paused: pause != nil)

        // A pause running out is a moment in time, not a change in the model: look again then.
        pauseEnd?.invalidate()
        pauseEnd = nil
        if let endsAt = pause?.endsAt {
            let timer = Timer(timeInterval: max(0, endsAt.timeIntervalSinceNow), repeats: false) { [weak self] _ in
                Task { @MainActor in self?.trackPause() }
            }
            RunLoop.main.add(timer, forMode: .common)
            pauseEnd = timer
        }
    }

    private func show(paused: Bool) {
        self.paused = paused
        guard let button = item.button else { return }
        let label = paused ? model.lang.pick(Strings.trayPaused) : "Save My Eyes"
        button.image = paused ? TrayIcon.paused : TrayIcon.normal
        button.toolTip = label
        button.setAccessibilityLabel(label)
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            windows.closeMenu()
            // Attaching the menu only for this click keeps left click free for the popover.
            item.menu = menu
            sender.performClick(nil)
            item.menu = nil
        } else {
            windows.toggleMenu()
        }
    }

    @objc private func openMenu() {
        windows.openMenu(pane: .menu)
    }

    @objc private func startLongBreak() {
        Log.info("tray", "start long break now")
        model.startLongBreakNow()
    }

    @objc private func quit() {
        model.quit()
    }
}
