// Full-screen cover for one display (port of `build_cover` + `macos::elevate_cover_window`):
// borderless, above the menu bar and the Dock, on every Space including other apps'
// fullscreen Spaces. Sized to the screen frame instead of `toggleFullScreen` (a new Space).
//
// Escape hatch (`EscapeRules`): the SwiftUI content reports its exit button through a
// `SkipBeacon`. Once a second the window checks the button is laid out on screen and usable;
// after `EscapeRules.fallbackAfter` seconds without one, a native AppKit button appears
// bottom-centre, drawn outside the SwiftUI view so a broken or blank view cannot hide it.

import AppKit
import SwiftUI

/// Where a cover's SwiftUI exit button is, as the view last laid it out (in the hosting
/// view's coordinates), and whether it still does something when clicked.
@MainActor
final class SkipBeacon {
    private(set) var frame: CGRect?
    private(set) var usable = true

    func report(frame: CGRect) { self.frame = frame }
    func report(usable: Bool) { self.usable = usable }
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
    private let fallbackButton: NSButton
    private let onEscape: () -> Void
    private var fallbackTimer: Timer?
    /// When the exit button stopped being reachable (or the cover opened, until it first is).
    private var unreachableSince: Date? = Date()

    /// - Parameters:
    ///   - beacon: filled in by `rootView`'s exit button.
    ///   - fallbackTitle: label of the native fallback button, in the current language.
    ///   - onEscape: what the fallback button does (skip the break, closing every cover).
    init<Content: View>(screen: NSScreen, rootView: Content, beacon: SkipBeacon,
                        fallbackTitle: String, onEscape: @escaping () -> Void) {
        displayID = screen.displayID
        self.beacon = beacon
        self.onEscape = onEscape
        let hosting = NSHostingView(rootView: rootView)
        // The window is sized to the screen, never to the SwiftUI content.
        hosting.sizingOptions = []
        self.hosting = hosting
        fallbackButton = FirstClickButton(title: fallbackTitle, target: nil, action: nil)
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        title = "Save My Eyes"
        isReleasedWhenClosed = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear

        // The glass (with the SwiftUI view inside) and the fallback button are siblings, so
        // the button never depends on the hosting view drawing anything.
        let root = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        let glass = GlassBacking.wrap(hosting, fallback: .fullScreenUI, cornerRadius: 0)
        glass.frame = root.bounds
        glass.autoresizingMask = [.width, .height]
        root.addSubview(glass)

        fallbackButton.target = self
        fallbackButton.action = #selector(fallbackClicked)
        fallbackButton.bezelStyle = .push
        fallbackButton.controlSize = .large
        fallbackButton.font = .systemFont(ofSize: NSFont.systemFontSize(for: .large), weight: .medium)
        fallbackButton.isHidden = true
        fallbackButton.setAccessibilityLabel(fallbackTitle)
        fallbackButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(fallbackButton)
        NSLayoutConstraint.activate([
            fallbackButton.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            fallbackButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -64),
        ])
        contentView = root
        place(on: screen)

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkSkipButton() }
        }
        // `.common` so it keeps running while a control tracks the mouse.
        RunLoop.main.add(timer, forMode: .common)
        fallbackTimer = timer
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
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        let callback = onClose
        onClose = nil
        super.close()
        callback?()
    }

    // MARK: Fallback

    private func checkSkipButton() {
        let now = Date()
        let reachable = EscapeRules.skipButtonReachable(frame: beacon.frame, usable: beacon.usable, in: hosting.bounds.size)
        if reachable {
            unreachableSince = nil
        } else if unreachableSince == nil {
            unreachableSince = now
        }
        let show = EscapeRules.showsFallback(reachable: reachable, unreachableSince: unreachableSince, now: now)
        guard show == fallbackButton.isHidden else { return }
        fallbackButton.isHidden = !show
        if show {
            Log.warn("windows", "exit button unreachable on display \(displayID) (frame \(beacon.frame.map { "\($0)" } ?? "none"), usable \(beacon.usable), cover \(hosting.bounds.size)): showing the fallback button")
            // The broken view may hold the keyboard; give Return/Space to the fallback.
            makeFirstResponder(fallbackButton)
        }
    }

    @objc private func fallbackClicked() {
        Log.warn("windows", "fallback skip button clicked on display \(displayID)")
        onEscape()
    }
}

/// Acts on the first click even when its window is not key (blank covers never are, and the
/// app may have lost activation): a stock `NSButton` spends that click focusing the window.
private final class FirstClickButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
