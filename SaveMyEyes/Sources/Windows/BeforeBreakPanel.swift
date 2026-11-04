// Notification-style card top-right of the primary display (port of
// `open_before_break_window` + `macos::style_panel`): borderless non-activating panel on
// every Space, glass with an 18 pt radius, sized to the SwiftUI content, never steals focus.

import AppKit
import SwiftUI

@MainActor
final class BeforeBreakPanel: NSPanel {
    static let width: CGFloat = 360
    static let margin: CGFloat = 12
    static let cornerRadius: CGFloat = 18

    /// Fired once when the panel closes, for any reason.
    var onClose: (() -> Void)?

    private let host: NSHostingController<BeforeBreakView>
    private var sizeObservation: NSKeyValueObservation?
    private var anchorScreen: NSScreen?

    init(model: AppModel) {
        host = NSHostingController(rootView: BeforeBreakView(model: model))
        host.sizingOptions = [.preferredContentSize]
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        title = "Save My Eyes"
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        // Clicks on buttons do not make it key; a control that needs typing still can.
        becomesKeyOnlyIfNeeded = true
        contentView = GlassBacking.wrap(host.view, fallback: .popover, cornerRadius: Self.cornerRadius)
        // Re-fit whenever the SwiftUI content changes height (grows downwards).
        sizeObservation = host.observe(\.preferredContentSize, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.fit() }
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Order front at the top-right of `screen`'s work area without taking focus.
    func show(on screen: NSScreen?) {
        anchorScreen = screen
        fit()
        orderFrontRegardless()
    }

    private func fit() {
        var height = host.preferredContentSize.height
        if height <= 0 { height = host.view.fittingSize.height }
        guard height > 0 else { return }
        height = ceil(height)
        guard let area = (anchorScreen ?? screen ?? NSScreen.main)?.visibleFrame else { return }
        let frame = NSRect(
            x: area.maxX - Self.width - Self.margin,
            y: area.maxY - Self.margin - height,
            width: Self.width,
            height: height
        )
        guard frame != self.frame else { return }
        setFrame(frame, display: true)
        invalidateShadow()
    }

    override func close() {
        let callback = onClose
        onClose = nil
        sizeObservation = nil
        super.close()
        callback?()
    }
}
