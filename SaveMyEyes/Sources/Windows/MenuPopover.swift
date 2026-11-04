// The menu: an NSPopover under the status item (replaces the Tauri `menu` window). Transient
// (closes on a click outside or Escape), system material, follows the SwiftUI content height.

import AppKit
import SwiftUI

@MainActor
final class MenuPopover: NSObject, NSPopoverDelegate {
    private let model: AppModel
    private var popover: NSPopover?
    private var escapeMonitor: Any?
    /// When the popover last closed: a click on the status item first closes the transient
    /// popover (mouse down outside) and then toggles it (mouse up); this keeps it closed.
    private var closedAt = Date.distantPast

    var isShown: Bool { popover?.isShown ?? false }
    var closedJustNow: Bool { Date().timeIntervalSince(closedAt) < 0.3 }

    init(model: AppModel) {
        self.model = model
    }

    func show(pane: MenuPane, relativeTo anchor: NSView) {
        NSApp.forceActivate()
        if let popover, popover.isShown {
            popover.contentViewController?.view.window?.makeKey()
            return
        }
        guard anchor.window != nil else {
            Log.warn("windows", "menu: status item button is not in the menu bar yet")
            return
        }
        let host = NSHostingController(rootView: MenuRootView(model: model, initialPane: pane))
        host.sizingOptions = [.preferredContentSize]
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = host
        popover.delegate = self
        self.popover = popover
        popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            let window = event.window
            let closed = MainActor.assumeIsolated { () -> Bool in
                guard let popover = self?.popover, window === popover.contentViewController?.view.window else { return false }
                popover.performClose(nil)
                return true
            }
            return closed ? nil : event
        }
        Log.info("windows", "menu opened on \(pane.rawValue)")
    }

    func close() {
        popover?.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        escapeMonitor = nil
        popover = nil
        closedAt = Date()
        Log.info("windows", "menu closed")
    }
}
