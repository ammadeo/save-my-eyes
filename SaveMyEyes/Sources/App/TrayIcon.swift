// The menu-bar icon, drawn rather than shipped as PNGs so both states share one ring to the
// pixel and stay sharp at any scale: the eyeball ring with a plus for its pupil, or with
// pause bars while breaks are on hold (the SF Symbols habit of swapping the glyph inside an
// unchanged outline, as in `plus.circle` / `pause.circle`). A monochrome template either way,
// so the menu bar tints it.
//
// The ring is 16pt across, the size of a circled SF Symbol in the menu bar, so it sits level
// with its neighbours. Every edge of the pupil lands on a half point (a whole pixel at 2x).

import AppKit

enum TrayIcon {
    static let normal = image(paused: false)
    static let paused = image(paused: true)

    private static func image(paused: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            NSColor.black.setStroke()
            let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1.75, dy: 1.75))
            ring.lineWidth = 1.5
            ring.stroke()

            let (x, y) = (rect.midX, rect.midY)
            let pupil = NSBezierPath()
            pupil.lineCapStyle = .round
            if paused {
                pupil.lineWidth = 2.5
                for barX in [x - 2.25, x + 2.25] {
                    pupil.move(to: NSPoint(x: barX, y: y - 2.75))
                    pupil.line(to: NSPoint(x: barX, y: y + 2.75))
                }
            } else {
                pupil.lineWidth = 3
                pupil.move(to: NSPoint(x: x, y: y - 3))
                pupil.line(to: NSPoint(x: x, y: y + 3))
                pupil.move(to: NSPoint(x: x - 3, y: y))
                pupil.line(to: NSPoint(x: x + 3, y: y))
            }
            pupil.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
