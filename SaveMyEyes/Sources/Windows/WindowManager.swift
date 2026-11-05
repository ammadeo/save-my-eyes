// The window layer driven by `AppModel` (port of `src-tauri/src/windows.rs`). Every call is
// idempotent. Closing a break window for any reason is reported to the model, deferred one
// turn so the scheduler is never re-entered from inside a close.
//
// While a break cover is up, the escape hatch (`EscapeRules`) is armed: each cover's native
// fallback button ends in `escapeBreak(reason:)`, which closes the covers here instead of
// trusting the scheduler to, and `CoverWatchdog` watches for a hung main thread.

import AppKit
import SwiftUI

@MainActor
final class WindowManager: NSObject, WindowCoordinating {
    private let model: AppModel
    /// The status item button the menu popover hangs from.
    weak var menuAnchor: NSView?

    private lazy var menu = MenuPopover(model: model)
    private var beforeBreak: BeforeBreakPanel?
    private var breakCover: CoverWindow?
    private var blankCovers: [CoverWindow] = []
    private var screenObserver: NSObjectProtocol?
    private let watchdog = CoverWatchdog()
    private var escapeArmed = false

    private static let fallbackTitle = L("Skip break", "Pomiń przerwę")

    init(model: AppModel) {
        self.model = model
    }

    /// The display that gets the card and the break cover.
    private var primaryScreen: NSScreen? { NSScreen.main ?? NSScreen.screens.first }

    // MARK: Menu

    func openMenu(pane: MenuPane) {
        guard let anchor = menuAnchor else {
            Log.warn("windows", "openMenu: no status item")
            return
        }
        menu.show(pane: pane, relativeTo: anchor)
    }

    func closeMenu() {
        menu.close()
    }

    /// Status item left click.
    func toggleMenu() {
        if menu.isShown {
            menu.close()
        } else if !menu.closedJustNow {
            openMenu(pane: .menu)
        }
    }

    // MARK: Before-break card

    func openBeforeBreak() {
        guard beforeBreak == nil else { return }
        // Both live top-right; the card takes precedence over an open menu.
        menu.close()
        let panel = BeforeBreakPanel(model: model)
        panel.onClose = { [weak self, model] in
            self?.beforeBreak = nil
            Log.info("windows", "before-break closed")
            Task { @MainActor in model.beforeBreakWindowClosed() }
        }
        beforeBreak = panel
        panel.show(on: primaryScreen)
        Log.info("windows", "before-break opened at \(panel.frame)")
    }

    func closeBeforeBreak() {
        beforeBreak?.close()
    }

    // MARK: Break covers

    func openBreakCovers() {
        closeBeforeBreak()
        if let breakCover {
            NSApp.forceActivate()
            breakCover.makeKeyAndOrderFront(nil)
            return
        }
        guard let screen = primaryScreen else {
            Log.error("windows", "openBreakCovers: no screen")
            return
        }
        let cover = makeCover(on: screen) { BreakView(model: self.model, beacon: $0) }
        cover.onClose = { [weak self, model] in
            guard let self else { return }
            self.breakCover = nil
            self.stopObservingScreens()
            self.disarmEscape()
            Log.info("windows", "break cover closed")
            Task { @MainActor in model.breakWindowClosed() }
        }
        breakCover = cover
        armEscape()
        syncBlankCovers()
        startObservingScreens()
        NSApp.forceActivate()
        cover.makeKeyAndOrderFront(nil)
        Log.info("windows", "break cover opened at \(cover.frame), \(blankCovers.count) blank cover(s)")
    }

    func closeBreakWindows() {
        closeBeforeBreak()
        let blanks = blankCovers
        blankCovers = []
        blanks.forEach { $0.close() }
        breakCover?.close()
        disarmEscape()
    }

    // MARK: Escape hatch

    /// Close every cover now and end the break, whatever state the scheduler is in. Closing
    /// the break cover reports it to the model (which schedules the next break); the check
    /// after it covers a scheduler that somehow still thinks the break is on. Exactly one
    /// of the two reschedules, in either order.
    func escapeBreak(reason: String) {
        guard breakCover != nil || !blankCovers.isEmpty else { return }
        Log.warn("windows", "escaping the break (\(reason)): closing \(blankCovers.count + (breakCover == nil ? 0 : 1)) cover(s)")
        closeBreakWindows()
        Task { @MainActor [model] in
            if model.breakState.phase == .active { model.endBreak() }
        }
    }

    /// The exit button ended the break, which normally closes the covers at once. If these
    /// same covers are still up a second later, escape.
    func ensureBreakCoversClosed() {
        guard let cover = breakCover else {
            if !blankCovers.isEmpty { escapeBreak(reason: "blank covers left without a break cover") }
            return
        }
        Task { @MainActor [weak self, weak cover] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, let cover, cover === self.breakCover else { return }
            self.escapeBreak(reason: "exit button did not close the cover")
        }
    }

    private func makeCover<Content: View>(on screen: NSScreen, _ content: (SkipBeacon) -> Content) -> CoverWindow {
        let beacon = SkipBeacon()
        return CoverWindow(screen: screen, rootView: content(beacon), beacon: beacon,
                           fallbackTitle: model.t(Self.fallbackTitle)) { [weak self] in
            self?.escapeBreak(reason: "fallback button")
        }
    }

    private func armEscape() {
        guard !escapeArmed else { return }
        escapeArmed = true
        watchdog.start()
    }

    private func disarmEscape() {
        guard escapeArmed else { return }
        escapeArmed = false
        watchdog.stop()
    }

    /// One blank cover per display other than the break cover's; follows plugged and
    /// unplugged displays while the break is on.
    private func syncBlankCovers() {
        guard let breakCover else { return }
        let screens = NSScreen.screens
        // The break cover's display went away: move it to the primary one.
        if let screen = screens.first(where: { $0.displayID == breakCover.displayID }) ?? primaryScreen {
            breakCover.place(on: screen)
        }
        let others = screens.filter { $0.displayID != breakCover.displayID }
        let wanted = Set(others.map(\.displayID))
        let gone = blankCovers.filter { !wanted.contains($0.displayID) }
        blankCovers.removeAll { !wanted.contains($0.displayID) }
        gone.forEach { $0.close() }
        for screen in others {
            if let existing = blankCovers.first(where: { $0.displayID == screen.displayID }) {
                existing.place(on: screen)
            } else {
                let blank = makeCover(on: screen) { BlankCoverView(model: self.model, beacon: $0) }
                blankCovers.append(blank)
                blank.orderFrontRegardless()
            }
        }
    }

    private func startObservingScreens() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.syncBlankCovers()
                Log.info("windows", "screens changed: \(NSScreen.screens.count) display(s), \(self.blankCovers.count) blank cover(s)")
            }
        }
    }

    private func stopObservingScreens() {
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        screenObserver = nil
    }
}

extension NSApplication {
    /// Make this accessory app active so its popover or cover becomes key and gets the
    /// keyboard. `activate()` (macOS 14) is cooperative and is refused while the user is busy
    /// in another app, which would leave the break cover without keyboard focus; the
    /// older call still takes focus. Called through `AnyObject` to skip the deprecation.
    func forceActivate() {
        (self as AnyObject).activate(ignoringOtherApps: true)
    }
}
