// DESIGN.md tokens as Swift: sage on glass, alpha labels, system font at Apple's macOS sizes.
// The oklch values of DESIGN.md are converted to sRGB once (see the comments); every colour
// follows the effective appearance (light / dark, and Increase Contrast).

import AppKit
import SwiftUI

/// The four appearances a token can resolve to.
private enum Look {
    case light, dark, lightHC, darkHC

    static func of(_ appearance: NSAppearance) -> Look {
        switch appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]) {
        case .darkAqua?: .dark
        case .accessibilityHighContrastAqua?: .lightHC
        case .accessibilityHighContrastDarkAqua?: .darkHC
        default: .light
        }
    }
}

private func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

/// A colour with light / dark values, and optional Increase Contrast overrides.
private func dynamic(light: NSColor, dark: NSColor, lightHC: NSColor? = nil, darkHC: NSColor? = nil) -> Color {
    Color(nsColor: NSColor(name: nil) { appearance in
        switch Look.of(appearance) {
        case .light: light
        case .dark: dark
        case .lightHC: lightHC ?? light
        case .darkHC: darkHC ?? dark
        }
    })
}

// Label hues: oklch(22% 0.02 150) and oklch(97% 0.01 150).
private let ink = (0.0783, 0.1149, 0.0850)
private let paper = (0.9436, 0.9690, 0.9473)
private func inkA(_ a: Double) -> NSColor { rgb(ink.0, ink.1, ink.2, a) }
private func paperA(_ a: Double) -> NSColor { rgb(paper.0, paper.1, paper.2, a) }
private func whiteA(_ a: Double) -> NSColor { rgb(1, 1, 1, a) }

enum Theme {
    // MARK: Colours

    /// Sage: oklch(52% 0.07 150) / oklch(76% 0.08 150); HC oklch(44%) / oklch(82%).
    static let accent = dynamic(
        light: rgb(0.2927, 0.4567, 0.3269), dark: rgb(0.5513, 0.7524, 0.5897),
        lightHC: rgb(0.2050, 0.3663, 0.2414), darkHC: rgb(0.6247, 0.8285, 0.6627))
    /// oklch(46% 0.07 150) / oklch(70% 0.08 150).
    static let accentPressed = dynamic(
        light: rgb(0.2267, 0.3886, 0.2625), dark: rgb(0.4794, 0.6777, 0.5182),
        lightHC: rgb(0.17, 0.31, 0.20), darkHC: rgb(0.5513, 0.7524, 0.5897))
    /// oklch(99% 0.005 150) / oklch(20% 0.03 150).
    static let onAccent = dynamic(light: rgb(0.9783, 0.9911, 0.9802), dark: rgb(0.0452, 0.1014, 0.0575))

    static let label = dynamic(light: inkA(0.9), dark: paperA(0.9),
                               lightHC: rgb(0.0218, 0.0531, 0.0272), darkHC: rgb(1, 1, 1))
    static let labelSecondary = dynamic(light: inkA(0.65), dark: paperA(0.65), lightHC: inkA(0.82), darkHC: paperA(0.82))
    static let labelTertiary = dynamic(light: inkA(0.3), dark: paperA(0.3), lightHC: inkA(0.6), darkHC: paperA(0.6))

    static let surface = dynamic(light: whiteA(0.45), dark: whiteA(0.07), lightHC: whiteA(0.7), darkHC: rgb(0, 0, 0, 0.35))
    /// Floating cards on the cover.
    static let surfaceRaised = dynamic(light: whiteA(0.6), dark: whiteA(0.12), lightHC: whiteA(0.85), darkHC: rgb(0, 0, 0, 0.5))
    static let fill = dynamic(light: inkA(0.06), dark: paperA(0.09))
    static let fillPressed = dynamic(light: inkA(0.1), dark: paperA(0.16))
    static let separator = dynamic(light: inkA(0.1), dark: paperA(0.1), lightHC: inkA(0.35), darkHC: paperA(0.35))
    /// Slider tint: oklch(55% 0.01 150) / oklch(80% 0.01 150).
    static let controlNeutral = dynamic(light: rgb(0.4298, 0.4519, 0.4331), dark: rgb(0.7270, 0.7512, 0.7305))
    /// oklch(50% 0.11 75) / oklch(78% 0.12 80).
    static let warning = dynamic(light: rgb(0.5298, 0.3460, 0.0), dark: rgb(0.8766, 0.6840, 0.3393))
    /// oklch(50% 0.16 25) / oklch(76% 0.13 25).
    static let destructive = dynamic(light: rgb(0.6736, 0.1899, 0.1907), dark: rgb(0.9757, 0.5590, 0.5285))

    // MARK: Shape and space

    enum Radius {
        static let control: CGFloat = 8
        static let controlXL: CGFloat = 12
        static let group: CGFloat = 14
        static let panel: CGFloat = 18
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        /// clamp(32px, 5vw, 64px)
        static func cover(width: CGFloat) -> CGFloat { min(max(width * 0.05, 32), 64) }
    }

    static let hairline: CGFloat = 0.5
}

// MARK: - Typography

extension Font {
    /// Countdown on the cover: light, tabular, clamp(56, 9vw, 96).
    static func smeDisplay(width: CGFloat) -> Font {
        .system(size: min(max(width * 0.09, 56), 96), weight: .light).monospacedDigit()
    }
    /// 26/32 regular.
    static let smeLargeTitle = Font.system(size: 26, weight: .regular)
    /// 17/22 medium.
    static let smeTitle2 = Font.system(size: 17, weight: .medium)
    /// 13/16 semibold.
    static let smeHeadline = Font.system(size: 13, weight: .semibold)
    /// 13/16 regular.
    static let smeBody = Font.system(size: 13, weight: .regular)
    /// 13/16 medium: push-button labels.
    static let smeButton = Font.system(size: 13, weight: .medium)
    /// 11/14 regular.
    static let smeFootnote = Font.system(size: 11, weight: .regular)
    /// 15/20 medium: the cover's exit button.
    static let smeControlXL = Font.system(size: 15, weight: .medium)
}

extension String {
    /// `::first-letter { text-transform: uppercase }`
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
