// The native material painted behind a hosted SwiftUI view (the views paint no background).
// macOS 26+: Liquid Glass (`NSGlassEffectView`, regular) tinted sage, DESIGN.md `glass-tint`.
// Before 26: an `NSVisualEffectView` material (the tint is glass-only; the radius still rounds it).

import AppKit

enum GlassBacking {
    /// Sage at 0.14 alpha (DESIGN.md `glass-tint`).
    static let tint = NSColor(srgbRed: 122 / 255, green: 158 / 255, blue: 134 / 255, alpha: 0.14)

    /// A view filling its frame with the material and `content` on top, sized to fill it.
    @MainActor
    static func wrap(_ content: NSView, fallback: NSVisualEffectView.Material, cornerRadius: CGFloat) -> NSView {
        content.autoresizingMask = [.width, .height]
        if #available(macOS 26, *) {
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.tintColor = tint
            glass.cornerRadius = cornerRadius
            glass.contentView = content
            return glass
        }
        let effect = NSVisualEffectView()
        effect.material = fallback
        effect.blendingMode = .behindWindow
        effect.state = .active
        if cornerRadius > 0 {
            effect.wantsLayer = true
            effect.layer?.cornerRadius = cornerRadius
            effect.layer?.cornerCurve = .continuous
            effect.layer?.masksToBounds = true
        }
        content.frame = effect.bounds
        effect.addSubview(content)
        return effect
    }
}
