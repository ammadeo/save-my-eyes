// Menu-bar status item (port of `src-tauri/src/tray.rs`): template icon, left click toggles
// the menu popover, right click (or control-click) shows Open / Start long break now / Quit.

import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let item: NSStatusItem
    private let model: AppModel
    private let windows: WindowManager
    private let menu = NSMenu()
    private let openItem = NSMenuItem()
    private let longBreakItem = NSMenuItem()
    private let quitItem = NSMenuItem()

    var button: NSStatusBarButton? { item.button }

    init(model: AppModel, windows: WindowManager) {
        self.model = model
        self.windows = windows
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = item.button {
            let image = NSImage(named: "tray")
            image?.isTemplate = true
            if image == nil { Log.warn("tray", "tray image missing from the bundle") }
            button.image = image
            button.toolTip = "Save My Eyes"
            button.setAccessibilityLabel("Save My Eyes")
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
        Log.info("tray", "status item ready")
    }

    /// Re-label the right-click menu after a language change.
    func relabel(_ lang: Lang) {
        openItem.title = lang.pick(Strings.trayOpen)
        longBreakItem.title = lang.pick(Strings.trayLongBreak)
        quitItem.title = lang.pick(Strings.trayQuit)
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
