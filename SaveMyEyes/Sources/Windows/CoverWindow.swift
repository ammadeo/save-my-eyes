// Full-screen cover for one display (port of `build_cover` + `macos::elevate_cover_window`):
// borderless, above the menu bar and the Dock, on every Space including other apps'
// fullscreen Spaces. Sized to the screen frame instead of `toggleFullScreen` (a new Space).
//
// Escape hatch (`EscapeRules`): the SwiftUI content reports its exit button through a
// `SkipBeacon`, and `exitReachable` says whether that button is on screen.

import AppKit
import SwiftUI

/// Where a cover's SwiftUI exit button is, as the view last laid it out (in the hosting
/// view's coordinates).
@MainActor
final class SkipBeacon {
    private(set) var frame: CGRect?

    func report(frame: CGRect) { self.frame = frame }
}

extension View {
    /// On a cover's exit button: report its frame to the window (escape hatch).
    func reportsSkipButton(to beacon: SkipBeacon?) -> some View {
        background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)
                Color.clear
                    .onAppear { beacon?.report(frame: frame) }
                    .onChange(of: frame) { beacon?.report(frame: frame) }
            }
        }
    }
}

@MainActor
final class CoverWindow: NSWindow {
    /// Fired once when the window closes, for any reason.
    var onClose: (() -> Void)?
    /// `CGDirectDisplayID` of the display this cover sits on.
    private(set) var displayID: CGDirectDisplayID

    private let beacon: SkipBeacon
    private let hosting: NSView

    /// Is this cover's exit button laid out on screen?
    var exitReachable: Bool {
        EscapeRules.skipButtonReachable(frame: beacon.frame, in: hosting.bounds.size)
    }

    /// `beacon` is filled in by `rootView`'s exit button.
    init<Content: View>(screen: NSScreen, rootView: Content, beacon: SkipBeacon) {
        displayID = screen.displayID
        self.beacon = beacon
        let hosting = NSHostingView(rootView: rootView)
        // The window is sized to the screen, never to the SwiftUI content.
        hosting.sizingOptions = []
        self.hosting = hosting
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        title = "Save My Eyes"
        isReleasedWhenClosed = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
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
