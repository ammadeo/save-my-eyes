// Full-screen cover for one display (port of `build_cover` + `macos::elevate_cover_window`):
// borderless, above the menu bar and the Dock, on every Space including other apps'
// fullscreen Spaces. Sized to the screen frame instead of `toggleFullScreen` (a new Space).

import AppKit
import SwiftUI

@MainActor
final class CoverWindow: NSWindow {
    /// Fired once when the window closes, for any reason.
    var onClose: (() -> Void)?
    /// `CGDirectDisplayID` of the display this cover sits on.
    private(set) var displayID: CGDirectDisplayID

    init<Content: View>(screen: NSScreen, rootView: Content) {
        displayID = screen.displayID
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        title = "Save My Eyes"
        isReleasedWhenClosed = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        let hosting = NSHostingView(rootView: rootView)
        // The window is sized to the screen, never to the SwiftUI content.
        hosting.sizingOptions = []
        contentView = GlassBacking.wrap(hosting, fallback: .fullScreenUI, cornerRadius: 0)
        place(on: screen)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Covers may sit over the menu bar; never let AppKit push them below it.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    func place(on screen: NSScreen) {
        displayID = screen.displayID
        if frame != screen.frame {
            setFrame(screen.frame, display: true)
        }
    }

    override func close() {
        let callback = onClose
        onClose = nil
        super.close()
        callback?()
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
