// Shared glass components (DESIGN.md › Components): grouped lists and rows, section titles,
// footnotes, push buttons, slider rows, progress bars and the closeable card of the cover.

import AppKit
import SwiftUI

// MARK: - Grouped list

/// Grouped list on the glass: surface, 0.5 pt separator border, 14 pt continuous corners.
/// Rows go in as children; put `GroupDivider` between them.
struct GlassGroup<Content: View>: View {
    var raised = false
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.group, style: .continuous)
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(raised ? Theme.surfaceRaised : Theme.surface, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Theme.separator, lineWidth: Theme.hairline))
    }
}

/// Hairline between rows, inset to the text start (12 pt, or 40 pt after a leading icon).
struct GroupDivider: View {
    var inset: CGFloat = 12
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: Theme.hairline)
            .padding(.leading, inset)
    }
}

/// Static row content: 40 pt min height, 12 pt side padding, 8 pt gap.
struct GlassRow<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 8) { content }
            .font(.smeBody)
            .foregroundStyle(Theme.label)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }
}

/// A tappable row: optional leading SF Symbol (secondary), label, trailing chevron or shortcut.
struct GlassRowButton: View {
    enum Trailing {
        case none
        case chevron
        case shortcut(String)
    }

    let title: String
    var icon: String? = nil
    var destructive = false
    var trailing: Trailing = .none
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.labelSecondary)
                        .frame(width: 20, height: 20)
                }
                Text(title)
                    .foregroundStyle(destructive ? Theme.destructive : Theme.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                switch trailing {
                case .none:
                    EmptyView()
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                        .accessibilityHidden(true)
                case .shortcut(let keys):
                    Text(keys)
                        .foregroundStyle(Theme.labelTertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(RowButtonStyle())
    }
}

struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RowButtonBody(configuration: configuration)
    }

    private struct RowButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            configuration.label
                .font(.smeBody)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .contentShape(Rectangle())
                .background(configuration.isPressed ? Theme.fillPressed : .clear)
                // Rows are clipped by their group, so the ring sits 3 pt inside the row.
                .overlay {
                    if focused {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Theme.accent, lineWidth: 3)
                            .padding(3)
                    }
                }
                .opacity(enabled ? 1 : 0.45)
        }
    }
}

// MARK: - Text

/// Section title above a group: footnote, medium, secondary, 12 pt in.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.labelSecondary)
            .padding(.leading, 12)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Footnote under a group: 11 pt secondary, 12 pt in.
struct Footnote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.smeFootnote)
            .foregroundStyle(Theme.labelSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "Save My Eyes" in the top-left of the covers.
struct HeaderTitle: View {
    let model: AppModel
    var body: some View {
        Text(model.t(Strings.title))
            .font(.smeHeadline)
            .foregroundStyle(Theme.labelSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Buttons

enum GlassButtonKind {
    /// The one sage control of a screen.
    case primary
    /// Surface background, label text, hairline border.
    case quiet
    /// Quiet with destructive text.
    case destructive
    /// No background until pressed, secondary label.
    case plain
}

enum GlassButtonSize {
    /// 24 pt
    case regular
    /// 28 pt
    case large
    /// 40 pt, 12 pt radius, 15 pt label: the cover's exit button only.
    case xl

    var minHeight: CGFloat {
        switch self {
        case .regular: 24
        case .large: 28
        case .xl: 40
        }
    }
    var radius: CGFloat { self == .xl ? Theme.Radius.controlXL : Theme.Radius.control }
    var hPadding: CGFloat {
        switch self {
        case .regular: 14
        case .large: 16
        case .xl: 20
        }
    }
    var vPadding: CGFloat {
        switch self {
        case .regular: 4
        case .large: 5
        case .xl: 8
        }
    }
    var font: Font { self == .xl ? .smeControlXL : .smeButton }
}

struct GlassButtonStyle: ButtonStyle {
    var kind: GlassButtonKind = .quiet
    var size: GlassButtonSize = .regular
    var fullWidth = false
    var hPadding: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(configuration: configuration, style: self)
    }

    private struct GlassButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let style: GlassButtonStyle
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: style.size.radius, style: .continuous)
            let pressed = configuration.isPressed && enabled
            configuration.label
                .font(style.size.font)
                .lineLimit(1)
                .foregroundStyle(foreground)
                .padding(.horizontal, style.hPadding ?? style.size.hPadding)
                .padding(.vertical, style.size.vPadding)
                .frame(minHeight: style.size.minHeight)
                .frame(maxWidth: style.fullWidth ? .infinity : nil)
                .background(background(pressed: pressed), in: shape)
                .overlay {
                    if style.kind == .quiet || style.kind == .destructive {
                        shape.strokeBorder(Theme.separator, lineWidth: Theme.hairline)
                    }
                }
                .contentShape(shape)
                // 3 pt opaque sage, 1 pt outside, following the button's own radius.
                .overlay {
                    if focused {
                        RoundedRectangle(cornerRadius: style.size.radius + 4, style: .continuous)
                            .strokeBorder(Theme.accent, lineWidth: 3)
                            .padding(-4)
                    }
                }
                .opacity(enabled ? 1 : 0.45)
                .animation(.easeOut(duration: 0.12), value: pressed)
        }

        private var foreground: Color {
            switch style.kind {
            case .primary: Theme.onAccent
            case .quiet: Theme.label
            case .destructive: Theme.destructive
            case .plain: configuration.isPressed ? Theme.label : Theme.labelSecondary
            }
        }

        private func background(pressed: Bool) -> Color {
            switch style.kind {
            case .primary: pressed ? Theme.accentPressed : Theme.accent
            case .quiet, .destructive: pressed ? Theme.fillPressed : Theme.surface
            case .plain: pressed ? Theme.fillPressed : .clear
            }
        }
    }
}

extension View {
    /// A glass push button. Draws its own focus ring (`focusEffectDisabled`).
    func glassButton(_ kind: GlassButtonKind = .quiet, size: GlassButtonSize = .regular, fullWidth: Bool = false, hPadding: CGFloat? = nil) -> some View {
        buttonStyle(GlassButtonStyle(kind: kind, size: size, fullWidth: fullWidth, hPadding: hPadding))
            .focusEffectDisabled()
    }
}

/// Label + optional trailing icon at 0.85 em, 0.7 opacity (legacy `ButtonIcon`).
struct IconLabel: View {
    let text: String
    var icon: String? = nil
    var leading = false

    var body: some View {
        HStack(spacing: 6) {
            if leading, let icon { symbol(icon) }
            Text(text.capitalizedFirst)
            if !leading, let icon { symbol(icon) }
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .imageScale(.small)
            .opacity(leading ? 1 : 0.7)
            .accessibilityHidden(true)
    }
}

/// 28 pt quiet circle with an icon (the card close button).
struct RoundIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.labelSecondary)
        }
        .buttonStyle(RoundButtonStyle())
        .focusEffectDisabled()
        .accessibilityLabel(label)
    }

    private struct RoundButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            RoundBody(configuration: configuration)
        }
        private struct RoundBody: View {
            let configuration: ButtonStyleConfiguration
            @Environment(\.isFocused) private var focused
            var body: some View {
                configuration.label
                    .frame(width: 28, height: 28)
                    .background(configuration.isPressed ? Theme.fillPressed : Theme.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.separator, lineWidth: Theme.hairline))
                    .overlay {
                        if focused { Circle().strokeBorder(Theme.accent, lineWidth: 3).padding(-4) }
                    }
                    .contentShape(Circle())
            }
        }
    }
}

// MARK: - Controls

/// Label left, value right in tabular numerals, a native neutral slider below.
/// `value` is in base units (seconds); the slider shows `value / scale`.
struct SliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step = 1
    var scale = 1
    var suffix = ""
    /// Shown alone instead of `0 suffix` when the value is 0.
    var zeroLabel: String? = nil

    private var display: Int { value / scale }
    private var valueText: String {
        if display == 0, let zeroLabel { return zeroLabel }
        return "\(display)\u{00a0}\(suffix)"
    }

    var body: some View {
        // Continuous slider snapped in the binding: a stepped macOS slider draws a tick per step.
        let lower = Double(range.lowerBound)
        let upper = Double(max(range.upperBound, range.lowerBound + 1))
        let snapped = Binding<Double>(
            get: { Double(display) },
            set: { raw in
                let s = Double(max(1, step))
                var v = lower + ((raw - lower) / s).rounded() * s
                if v > Double(range.upperBound) { v -= s }
                v = min(max(v, lower), Double(range.upperBound))
                let next = Int(v) * scale
                if next != value { value = next }
            })
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(label)
                    .foregroundStyle(Theme.label)
                Spacer(minLength: 8)
                Text(valueText)
                    .monospacedDigit()
                    .foregroundStyle(Theme.labelSecondary)
                    .fixedSize()
            }
            Slider(value: snapped, in: lower...upper)
                .labelsHidden()
                .tint(Theme.controlNeutral)
                .accessibilityLabel(label)
                .accessibilityValue(valueText)
        }
        .font(.smeBody)
        .padding(.horizontal, 12)
        .padding(.top, 9)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }
}

/// A row with a label and a native switch (sage when on).
struct SwitchRow: View {
    let label: String
    @Binding var isOn: Bool
    var disabled = false

    var body: some View {
        GlassRow {
            Text(label).frame(maxWidth: .infinity, alignment: .leading)
            Toggle(label, isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .tint(Theme.accent)
                .disabled(disabled)
        }
    }
}

/// Fill track, sage bar, pill. 4 pt in cards, 8 pt on the cover.
struct GlassProgressBar: View {
    /// 0...1
    let fraction: Double
    var height: CGFloat = 4
    var label: String
    var animated = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.fill)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(animated ? .linear(duration: 0.25) : nil, value: fraction)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((max(0, min(1, fraction)) * 100).rounded())) %")
    }
}

// MARK: - Cards

/// Raised card of the cover (idea, donation): stronger surface, hairline, 14 pt corners.
struct RaisedCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.group, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceRaised, in: shape)
            .overlay(shape.strokeBorder(Theme.separator, lineWidth: Theme.hairline))
    }
}

/// Floating card on the cover (settings, stop protection): title + close button. Escape closes.
/// Focus lands on the close button when the card appears. Floating cards overlap other
/// controls, so they blur what is under them.
struct CloseableCard<Content: View>: View {
    let title: String
    let closeLabel: String
    let onClose: () -> Void
    @ViewBuilder var content: Content
    @FocusState private var closeFocused: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.group, style: .continuous)
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(title.capitalizedFirst)
                    .font(.smeHeadline)
                    .foregroundStyle(Theme.label)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                RoundIconButton(systemName: "xmark", label: closeLabel, action: onClose)
                    .focused($closeFocused)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceRaised, in: shape)
        .background(.ultraThinMaterial, in: shape)
        .overlay(shape.strokeBorder(Theme.separator, lineWidth: Theme.hairline))
        .clipShape(shape)
        .onExitCommand(perform: onClose)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .onAppear {
            Task { @MainActor in closeFocused = true }
        }
    }
}

// MARK: - Images

enum BundleImage {
    /// Images ship in the `Images/` folder reference; fall back to the bundle root.
    static func url(_ name: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Images")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }

    @MainActor private static var cache: [String: NSImage] = [:]

    @MainActor static func load(_ name: String, _ ext: String = "svg") -> NSImage? {
        let key = "\(name).\(ext)"
        if let hit = cache[key] { return hit }
        guard let url = url(name, ext), let image = NSImage(contentsOf: url) else { return nil }
        cache[key] = image
        return image
    }
}

// MARK: - Links

extension View {
    /// Links inside `Text` open through the model (default browser).
    func opensLinks(with model: AppModel) -> some View {
        environment(\.openURL, OpenURLAction { url in
            model.openURL(url.absoluteString)
            return .handled
        })
    }
}

/// Builds footnote text with underlined label-coloured links.
func linkedText(_ parts: [(String, String?)]) -> AttributedString {
    var out = AttributedString()
    for (text, link) in parts {
        var piece = AttributedString(text)
        if let link, let url = URL(string: link) {
            piece.link = url
            piece.underlineStyle = .single
            piece.foregroundColor = Theme.label
        }
        out += piece
    }
    return out
}
